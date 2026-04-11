
import * as fs from 'fs';
import * as path from 'path';
import { DataSource } from 'typeorm';
import { Product } from '../modules/products/entities/product.entity';
import * as dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

dotenv.config();

async function importProducts() {
    console.log('TODO: Refactor import-products.ts to support new Product entity schema (Category relations, etc).');
    console.log('Use npm run seed instead.');
}

importProducts();
