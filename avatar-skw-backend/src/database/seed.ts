import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

import { User, UserRole, UserStatus } from '../modules/users/entities/user.entity';
import { DealerTier } from '../modules/users/entities/dealer-tier.entity';
import { Product } from '../modules/products/entities/product.entity';
import { Category } from '../modules/products/entities/category.entity';
import { Brand } from '../modules/brands/entities/brand.entity';

dotenv.config();

const SALT_ROUNDS = 12;

const dataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: [User, DealerTier, Product, Category, Brand],
  synchronize: true, // Auto-create schema if missing
  ssl:
    process.env.NODE_ENV === 'production'
      ? { rejectUnauthorized: false }
      : false,
});

async function hash(password: string) {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function seed() {
  await dataSource.initialize();

  const userRepo = dataSource.getRepository(User);
  const tierRepo = dataSource.getRepository(DealerTier);
  const categoryRepo = dataSource.getRepository(Category);
  const brandRepo = dataSource.getRepository(Brand);
  const productRepo = dataSource.getRepository(Product);

  /* ======================================================
     DEALER TIER
     ====================================================== */

  console.log('Seeding dealer tiers...');

  let standardTier = await tierRepo.findOne({ where: { name: 'Standard' } });
  if (!standardTier) {
    standardTier = tierRepo.create({
      name: 'Standard',
      discountPct: 5,
      creditTermsText: 'Net 15',
      active: true,
    });
    standardTier = await tierRepo.save(standardTier);
    console.log('Created dealer tier: Standard');
  }

  /* ======================================================
     USERS
     ====================================================== */

  console.log('Seeding users...');

  const usersToSeed = [
    {
      name: 'Super Admin',
      phone: '9999000001',
      email: 'superadmin@example.com',
      role: UserRole.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      password: 'Password@123',
    },
    {
      name: 'Admin User',
      phone: '9999000002',
      email: 'admin@example.com',
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
      password: 'Password@123',
    },
    {
      name: 'Dealer User',
      phone: '9999000003',
      email: 'dealer@example.com',
      role: UserRole.DEALER,
      status: UserStatus.APPROVED,
      password: 'Password@123',
      dealerTierId: standardTier.id,
      companyName: 'Dealer Co',
    },
    {
      name: 'Consumer User',
      phone: '9999000004',
      email: 'consumer@example.com',
      role: UserRole.CONSUMER,
      status: UserStatus.ACTIVE,
      password: 'Password@123',
    },
  ];

  for (const u of usersToSeed) {
    const existing = await userRepo.findOne({
      where: [{ phone: u.phone }, { email: u.email }],
    });

    if (existing) {
      // Force update password to ensure it matches
      existing.passwordHash = await hash(u.password);
      // Also ensure role/status are correct just in case
      existing.role = u.role;
      existing.status = u.status;

      await userRepo.save(existing);
      console.log(`✅ Updated existing user: ${u.phone} (Password reset)`);
      continue;
    }

    const passwordHash = await hash(u.password);

    const user = userRepo.create({
      name: u.name,
      phone: u.phone,
      email: u.email,
      role: u.role,
      status: u.status,
      passwordHash,
      dealerTierId: u.dealerTierId,
      companyName: u.companyName,
    });

    await userRepo.save(user);
    console.log(`Created user: ${u.phone} (${u.role})`);
  }

  /* ======================================================
     CATEGORIES & PRODUCTS
     ====================================================== */

  console.log('Seeding categories & products...');

  const productsFilePath = path.join(
    __dirname,
    'data',
    'products.json'
  );

  if (!fs.existsSync(productsFilePath)) {
    console.warn('⚠️ products.json not found — skipping product seeding');
  } else {
    const rawData = fs.readFileSync(productsFilePath, 'utf-8');
    const productsData = JSON.parse(rawData); // This is an array

    // 1. Extract and Seed Unique Categories
    const categoryNames = new Set(productsData.map((p: any) => p.category));
    const categoryMap = new Map<string, Category>();

    for (const name of categoryNames) {
      if (!name) continue;
      let category = await categoryRepo.findOne({ where: { name: name as string } });
      if (!category) {
        category = categoryRepo.create({ name: name as string });
        category = await categoryRepo.save(category);
        console.log(`Created category: ${name}`);
      }
      categoryMap.set(name as string, category);
    }

    // 1.5 Extract and Seed Unique Brands
    const brandNames = new Set(productsData.map((p: any) => p.brand));
    const brandMap = new Map<string, Brand>();

    for (const name of brandNames) {
      if (!name) continue;
      let brand = await brandRepo.findOne({ where: { name: name as string } });
      if (!brand) {
        brand = brandRepo.create({ name: name as string, isActive: true });
        brand = await brandRepo.save(brand);
        console.log(`Created brand: ${name}`);
      }
      brandMap.set(name as string, brand);
    }

    // 2. Seed Products
    for (const p of productsData) {
      // Flatten variations if they exist, or use product as is if no variations
      // The JSON provided has 'variations' array. We need to handle that.
      // Based on the file viewed: It has 'name', 'brand', 'category', 'variations'.
      // The variations contain 'sku', 'price', etc.
      // The 'Product' entity seems to map to a single SKU. 
      // If the backend treats each SKU as a product, we should iterate variations.

      if (p.variations && Array.isArray(p.variations)) {
        for (const v of p.variations) {
          let product = await productRepo.findOne({
            where: { sku: v.sku },
          });

          if (!product) {
            const category = categoryMap.get(p.category);

            product = productRepo.create({
              sku: v.sku,
              name: `${p.name} - ${v.specs?.Size || ''}`.trim(), // Append size to name for uniqueness if needed, or just use p.name but that might be duplicate names for different SKUs
              // Actually, traditionally Product Entity might have one name and multiple SKUs, 
              // but looking at valid fields: sku, name, price...
              // Let's use the parent name + variation size if useful.

              price: v.price || 0,
              description: p.name, // Use parent name as description or leave empty?
              category: category,
              currency: 'INR',
              hsn: v.specs?.HSN || '8516',
              gstPercent: parseFloat(v.specs?.GST) || 18,
              material: 'Stainless Steel', // Default or from specs?
              brandRel: brandMap.get(p.brand),
              // variant: v.specs?.Size, // Product entity has 'variant' field? Checked seed.ts line 174: variant: p.variant
              variant: v.specs?.Size,
              size: v.specs?.Size,
            });

            await productRepo.save(product);
            console.log(`Created product: ${v.sku}`);
          }
        }
      } else if (p.sku) {
        // Handle flat product if any (like in the demo file, but main file is nested)
        let product = await productRepo.findOne({
          where: { sku: p.sku },
        });

        if (!product) {
          const category = categoryMap.get(p.category);
          product = productRepo.create({
            sku: p.sku,
            name: p.name,
            price: p.price || 0,
            category: category,
            brandRel: brandMap.get(p.brand),
            currency: 'INR',
            hsn: p.specs?.HSN || '8516',
            gstPercent: 18,
          });
          await productRepo.save(product);
          console.log(`Created product: ${p.sku}`);
        }
      }
    }
  }

  await dataSource.destroy();
  console.log('✅ Seeding complete.');
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
