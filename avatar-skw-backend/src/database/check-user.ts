
import { DataSource } from 'typeorm';
import { User } from '../modules/users/entities/user.entity';
import { DealerTier } from '../modules/users/entities/dealer-tier.entity';
import { Category } from '../modules/products/entities/category.entity';
import { Brand } from '../modules/brands/entities/brand.entity';
import { Product } from '../modules/products/entities/product.entity';
import * as dotenv from 'dotenv';
dotenv.config();

const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [User, DealerTier, Category, Brand, Product],
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function checkUser() {
    await dataSource.initialize();
    const userRepo = dataSource.getRepository(User);
    const user = await userRepo.findOne({ where: { phone: '9999988888' } });

    if (user) {
        console.log(`User found: ${user.name} (Role: ${user.role}, Status: ${user.status})`);
    } else {
        console.log('User not found');
    }

    await dataSource.destroy();
}

checkUser().catch(console.error);
