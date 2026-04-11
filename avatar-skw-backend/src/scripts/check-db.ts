
import { DataSource } from 'typeorm';
import { Product } from '../modules/products/entities/product.entity';
import * as dotenv from 'dotenv';
import 'reflect-metadata';

dotenv.config();

async function checkDb() {
    const dataSource = new DataSource({
        type: 'postgres',
        url: process.env.DATABASE_URL,
        entities: [Product],
        synchronize: false,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });

    try {
        await dataSource.initialize();
        console.log('Connected to Database.');

        const productRepo = dataSource.getRepository(Product);
        const count = await productRepo.count();
        console.log(`Total Products: ${count}`);

        const sample = await productRepo.find({
            take: 5,
            order: { sku: 'ASC' },
            relations: ['brandRel']
        });
        console.log('First 5 products sorted by SKU:');
        console.table(sample.map(p => ({
            sku: p.sku,
            name: p.name,
            price: p.price,
            brand: p.brandRel?.name || 'N/A'
        })));

    } catch (error) {
        console.error('Error connecting to DB:', error);
    } finally {
        await dataSource.destroy();
    }
}

checkDb();
