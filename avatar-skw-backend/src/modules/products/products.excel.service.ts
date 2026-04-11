import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import * as ExcelJS from 'exceljs';
import { Product } from './entities/product.entity';
import { Brand } from '../brands/entities/brand.entity';
import { Category } from './entities/category.entity';
import { Readable } from 'stream';

@Injectable()
export class ProductsExcelService {
    constructor(
        @InjectRepository(Product)
        private productRepository: Repository<Product>,
        @InjectRepository(Brand)
        private brandRepository: Repository<Brand>,
        @InjectRepository(Category)
        private categoryRepository: Repository<Category>,
    ) { }

    async exportProducts(): Promise<Buffer> {
        const products = await this.productRepository.find({
            order: { createdAt: 'DESC' },
            relations: ['brandRel', 'category'],
        });
        const brands = await this.brandRepository.find({ where: { isActive: true }, order: { name: 'ASC' } });
        const categories = await this.categoryRepository.find({ where: { isActive: true }, order: { name: 'ASC' } });

        const workbook = new ExcelJS.Workbook();

        // 1. HIDDEN DATA SHEET (For Dropdowns)
        const dataSheet = workbook.addWorksheet('Data');
        dataSheet.state = 'hidden';

        // Add Brands
        dataSheet.getCell('A1').value = 'Brands';
        brands.forEach((b, i) => {
            dataSheet.getCell(`A${i + 2}`).value = b.name;
        });
        const brandRef = `Data!$A$2:$A$${brands.length + 1}`;

        // Add Categories
        dataSheet.getCell('B1').value = 'Categories';
        categories.forEach((c, i) => {
            dataSheet.getCell(`B${i + 2}`).value = c.name;
        });
        const categoryRef = `Data!$B$2:$B$${categories.length + 1}`;

        // Add Variation Types
        const varTypes = ['Color', 'Size', 'Color & Size', 'Style', 'Material', 'None'];
        dataSheet.getCell('C1').value = 'VarTypes';
        varTypes.forEach((v, i) => {
            dataSheet.getCell(`C${i + 2}`).value = v;
        });
        const varTypeRef = `Data!$C$2:$C$${varTypes.length + 1}`;

        // 2. MAIN PRODUCT SHEET
        const sheet = workbook.addWorksheet('Products');

        // Define Columns
        sheet.columns = [
            { header: 'ID (DO NOT EDIT)', key: 'id', width: 36, hidden: false }, // Keep visible but warn user, or hide if preferred. User asked to "hide product id".
            { header: 'SKU', key: 'sku', width: 15 },
            { header: 'Name', key: 'name', width: 30 },
            { header: 'Brand', key: 'brand', width: 15 },
            { header: 'Category', key: 'category', width: 15 },
            { header: 'Price', key: 'price', width: 12 },
            { header: 'MRP', key: 'mrp', width: 12 },
            { header: 'GST %', key: 'gst', width: 10 },
            { header: 'Group ID', key: 'groupId', width: 20 },
            { header: 'What Varies?', key: 'varType', width: 15 },
            { header: 'Variant (Color/Style)', key: 'variant', width: 20 },
            { header: 'Size', key: 'size', width: 10 },
            { header: 'Material', key: 'material', width: 15 },
            { header: 'Is Active', key: 'isActive', width: 10 },
            { header: 'Description', key: 'description', width: 40 },
        ];

        // Style Header
        const headerRow = sheet.getRow(1);
        headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 12 };
        headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1565C0' } }; // Blue Header
        headerRow.height = 30;

        // Add Data
        products.forEach((p) => {
            const row = sheet.addRow({
                id: p.id,
                sku: p.sku,
                name: p.name,
                brand: p.brandRel?.name || '',
                category: p.category?.name || '',
                price: Number(p.price),
                mrp: p.mrp ? Number(p.mrp) : 0,
                gst: p.gstPercent || 0,
                groupId: p.variationGroupId || '',
                varType: p.variationType || 'None',
                variant: p.variant || '',
                size: p.size || '',
                material: p.material || '',
                isActive: p.isActive, // will be boolean
                description: p.description || '',
            });
        });

        // Apply Styling and Validation to Rows
        const rowCount = products.length + 100; // Allow extra empty rows for new products

        for (let r = 2; r <= rowCount; r++) {
            const row = sheet.getRow(r);

            // 1. ID Column (A) -> Red, Locked
            const idCell = row.getCell(1);
            idCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFEBEE' } }; // Light Red
            idCell.font = { color: { argb: 'FFB71C1C' } }; // Dark Red Text

            // 2. Editable Columns (B to O) -> Green-ish tint for guidance
            for (let c = 2; c <= 15; c++) {
                const cell = row.getCell(c);
                // Apply light green to key fields (SKU, Name, Price)
                if (c >= 2 && c <= 8) {
                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF1F8E9' } }; // Light Green 
                }
            }

            // Brand Dropdown (D)
            sheet.getCell(`D${r}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: [brandRef],
                showErrorMessage: true,
                errorTitle: 'Invalid Brand',
                error: 'Please select a valid Brand from the list.',
            };

            // Category Dropdown (E)
            sheet.getCell(`E${r}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: [categoryRef],
                showErrorMessage: true,
                errorTitle: 'Invalid Category',
                error: 'Please select a valid Category.',
            };

            // Variation Type Dropdown (J)
            sheet.getCell(`J${r}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: [varTypeRef],
            };

            // Is Active Dropdown (N)
            // Using boolean directly in Excel sometimes creates checkbox or TRUE/FALSE. 
            // Better to standardise on TRUE/FALSE list
            sheet.getCell(`N${r}`).dataValidation = {
                type: 'list',
                allowBlank: false,
                formulae: ['"TRUE,FALSE"'],
                showErrorMessage: true,
                error: 'Value must be TRUE or FALSE'
            };
        }

        // Protection logic: User wanted HIDDEN ID. 
        // We can just set the column width to 0 or hidden property.
        // Making it protected is safer.
        sheet.getColumn('id').hidden = true; // Use wanted customized behavior

        // sheet.protect('pass', { selectLockedCells: true, selectUnlockedCells: true });
        // This locks everything unless we unlock specific cells. For import template, simplified approach:
        // Just hide ID.

        const buffer = await workbook.xlsx.writeBuffer();
        return Buffer.from(buffer as any);
    }

    async importProducts(fileBuffer: Buffer) {
        const workbook = new ExcelJS.Workbook();
        await workbook.xlsx.load(fileBuffer as any);
        const sheet = workbook.getWorksheet('Products');

        if (!sheet) {
            throw new BadRequestException('Invalid File: Missing "Products" sheet.');
        }

        // Cache Brands/Categories to Key-Value maps for O(1) lookup
        const allBrands = await this.brandRepository.find();
        const brandMap = new Map(allBrands.map(b => [b.name.toLowerCase().trim(), b.id]));

        const allCats = await this.categoryRepository.find();
        const catMap = new Map(allCats.map(c => [c.name.toLowerCase().trim(), c.id]));

        const productsToSave: Product[] = [];
        const errors: string[] = [];
        let newCount = 0;
        let updatedCount = 0;
        let skippedCount = 0;

        // 1. First Pass: Collect IDs to fetch existing data for comparison
        const sheetIds: string[] = [];
        sheet.eachRow((row, rowNumber) => {
            if (rowNumber === 1) return;
            const id = row.getCell(1).value?.toString().trim();
            if (id && id.length > 10) sheetIds.push(id);
        });

        // 2. Fetch Existing Products Map
        const existingProducts = await this.productRepository.find({ where: { id: In(sheetIds) } });
        const existingMap = new Map(existingProducts.map(p => [p.id, p]));

        // 3. Second Pass: Process and Compare
        sheet.eachRow((row, rowNumber) => {
            if (rowNumber === 1) return; // Skip Header

            // Helper to get safe string value
            const getVal = (idx: number) => {
                const val = row.getCell(idx).value;
                return val ? val.toString().trim() : '';
            };

            // Helper to get number
            const getNum = (idx: number) => {
                const val = row.getCell(idx).value;
                if (!val) return 0;
                return Number(val.toString());
            };

            // Helper to get bool
            const getBool = (idx: number) => {
                const val = row.getCell(idx).value;
                return val === true || val === 'true' || val === 'TRUE';
            };

            try {
                const id = getVal(1); // Hidden ID
                const sku = getVal(2);
                const name = getVal(3);
                const brandName = getVal(4);
                const catName = getVal(5);

                if (!name || !sku) return;

                // Validate Lookup
                const brandId = brandMap.get(brandName.toLowerCase());
                const categoryId = catMap.get(catName.toLowerCase());

                if (brandName && !brandId) {
                    errors.push(`Row ${rowNumber}: Brand "${brandName}" not found.`);
                    return;
                }
                if (catName && !categoryId) {
                    errors.push(`Row ${rowNumber}: Category "${catName}" not found.`);
                    return;
                }

                // Prepare Potential New State
                const newProduct = new Product();
                const isUpdate = id && id.length > 10;

                if (isUpdate) newProduct.id = id;
                newProduct.sku = sku;
                newProduct.name = name;
                newProduct.brandId = brandId;
                newProduct.categoryId = categoryId;
                newProduct.price = getNum(6);
                newProduct.mrp = getNum(7);
                newProduct.gstPercent = getNum(8);
                newProduct.variationGroupId = getVal(9) || null;
                newProduct.variationType = getVal(10) || null;
                newProduct.variant = getVal(11) || null;
                newProduct.size = getVal(12) || null;
                newProduct.material = getVal(13) || null;
                newProduct.isActive = getBool(14);
                newProduct.description = getVal(15);

                // Change Detection
                if (isUpdate) {
                    const existing = existingMap.get(id);
                    if (existing) {
                        const isSame =
                            existing.sku === newProduct.sku &&
                            existing.name === newProduct.name &&
                            existing.brandId === newProduct.brandId &&
                            existing.categoryId === newProduct.categoryId &&
                            Number(existing.price) === Number(newProduct.price) &&
                            Number(existing.mrp) === Number(newProduct.mrp) &&
                            existing.gstPercent === newProduct.gstPercent &&
                            existing.variationGroupId === newProduct.variationGroupId &&
                            existing.variationType === newProduct.variationType &&
                            existing.variant === newProduct.variant &&
                            existing.size === newProduct.size &&
                            existing.material === newProduct.material &&
                            existing.isActive === newProduct.isActive &&
                            existing.description === newProduct.description;

                        if (isSame) {
                            skippedCount++;
                            return; // SKIP SAVE
                        }
                    }
                    updatedCount++;
                } else {
                    newCount++;
                }

                productsToSave.push(newProduct);

            } catch (e) {
                errors.push(`Row ${rowNumber}: Error - ${e.message}`);
            }
        });

        if (productsToSave.length > 0) {
            await this.productRepository.save(productsToSave);
        }

        return {
            success: true,
            importedCount: productsToSave.length,
            newCount: newCount,
            updatedCount: updatedCount,
            skippedCount: skippedCount,
            errors: errors
        };
    }
}
