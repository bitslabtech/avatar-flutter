import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
import { User, UserRole } from '../modules/users/entities/user.entity';
import { DealerTier } from '../modules/users/entities/dealer-tier.entity';
import { Product } from '../modules/products/entities/product.entity';
import { Category } from '../modules/products/entities/category.entity';

dotenv.config();

const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [User, DealerTier, Product, Category],
    synchronize: false,
});

async function check() {
    await dataSource.initialize();
    console.log('Connected to DB');

    const userRepo = dataSource.getRepository(User);
    const phone = '9999000001';
    const password = 'Password@123';

    const user = await userRepo.findOne({ where: { phone } });

    if (!user) {
        console.error('❌ User NOT FOUND in DB');
    } else {
        console.log('✅ User Found:', {
            id: user.id,
            name: user.name,
            phone: user.phone,
            role: user.role,
            status: user.status,
            hashLength: user.passwordHash?.length,
        });

        const match = await bcrypt.compare(password, user.passwordHash);
        console.log(`🔑 Password Check ('${password}'):`, match ? 'MATCH ✅' : 'FAIL ❌');

        // Also try checking the hash directly stored just in case
        // const newHash = await bcrypt.hash(password, 12);
        // console.log('New Hash would be:', newHash);
    }

    await dataSource.destroy();
}

check().catch(console.error);
