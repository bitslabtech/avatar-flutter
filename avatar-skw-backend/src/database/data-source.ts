import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

import { User } from '../modules/users/entities/user.entity';
import { DealerTier } from '../modules/users/entities/dealer-tier.entity';
import { Product } from '../modules/products/entities/product.entity';
import { Category } from '../modules/products/entities/category.entity';

dotenv.config();

export const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: ['src/modules/**/entities/*.entity.ts'],
    migrations: ['src/database/migrations/*.ts'],
    synchronize: false,
    ssl:
        process.env.NODE_ENV === 'production'
            ? { rejectUnauthorized: false }
            : false,
});
