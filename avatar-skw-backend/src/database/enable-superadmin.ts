import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import { User, UserRole, UserStatus } from '../modules/users/entities/user.entity';
import { DealerTier } from '../modules/users/entities/dealer-tier.entity';
import { Product } from '../modules/products/entities/product.entity';
import { Category } from '../modules/products/entities/category.entity';
import { Brand } from '../modules/brands/entities/brand.entity';

dotenv.config();

const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [User, DealerTier, Product, Category, Brand],
    synchronize: false, // Do not sync schema, just data
    ssl:
        process.env.NODE_ENV === 'production'
            ? { rejectUnauthorized: false }
            : false,
});

async function enableSuperAdmin() {
    await dataSource.initialize();
    console.log('📦 Database connected');

    const userRepo = dataSource.getRepository(User);

    // Find the super admin
    const superAdmin = await userRepo.findOne({
        where: { role: UserRole.SUPER_ADMIN },
    });

    if (!superAdmin) {
        console.error('❌ Super Admin not found!');
        process.exit(1);
    }

    console.log(`Found Super Admin: ${superAdmin.name} (${superAdmin.email})`);
    console.log(`Current Status: ${superAdmin.status}`);

    if (superAdmin.status === UserStatus.ACTIVE) {
        console.log('✅ Super Admin is already active.');
    } else {
        superAdmin.status = UserStatus.ACTIVE;
        await userRepo.save(superAdmin);
        console.log('✅ Super Admin account has been ENABLED.');
    }

    await dataSource.destroy();
}

enableSuperAdmin().catch((err) => {
    console.error('❌ Failed to enable super admin:', err);
    process.exit(1);
});
