
import * as fs from 'fs';
import * as path from 'path';

function validateJson() {
    const jsonPath = path.join(__dirname, '../database/data/products.json');

    if (!fs.existsSync(jsonPath)) {
        console.error(`File not found at ${jsonPath}`);
        return;
    }

    try {
        const fileContent = fs.readFileSync(jsonPath, 'utf-8');
        const data = JSON.parse(fileContent);

        if (!Array.isArray(data)) {
            console.error('Error: Root is not an array.');
            return;
        }

        console.log(`Successfully parsed JSON. Found ${data.length} items.`);
        let errorCount = 0;
        const skuSet = new Set<string>();

        function checkSku(sku: string, location: string) {
            if (!sku) return;
            if (skuSet.has(sku)) {
                console.error(`Duplicate SKU found: ${sku} at ${location}`);
                errorCount++;
            } else {
                skuSet.add(sku);
            }
        }

        data.forEach((item, index) => {
            if (!item.name) { console.error(`Item ${index}: Missing 'name'`); errorCount++; }
            if (!item.brand) { console.error(`Item ${index}: Missing 'brand'`); errorCount++; }
            if (!item.category) { console.error(`Item ${index}: Missing 'category'`); errorCount++; }

            // Check top level SKU if checks are mixed (simple products)
            if (item.sku) checkSku(item.sku, `Item ${index} (${item.name})`);

            if (item.variations) {
                if (!Array.isArray(item.variations)) {
                    console.error(`Item ${index} (${item.name}): 'variations' is not an array.`);
                    errorCount++;
                } else {
                    item.variations.forEach((v, vIndex) => {
                        if (!v.sku) { console.error(`Item ${index} (${item.name}) Var ${vIndex}: Missing 'sku'`); errorCount++; }
                        if (v.sku) checkSku(v.sku, `Item ${index} (${item.name}) Var ${vIndex}`);

                        if (typeof v.price !== 'number') { console.error(`Item ${index} (${item.name}) Var ${vIndex}: 'price' is not a number`); errorCount++; }
                        if (typeof v.mrp !== 'number') { console.error(`Item ${index} (${item.name}) Var ${vIndex}: 'mrp' is not a number`); errorCount++; }
                    });
                }
            } else {
                // Simple product check
                // Although based on diff, user might be putting everything in variations for consistency or mixed.
                // Checking if simple product has price if no variations
                if (!item.variations && typeof item.price !== 'number' && !item.price) {
                    // It's possible some items are missing price if they are expected to be incomplete, but let's warn.
                    console.warn(`Item ${index} (${item.name}): Missing 'price' and has no variations.`);
                }
            }
        });

        if (errorCount === 0) {
            console.log('Validation PASSED: All simple checks passed.');
        } else {
            console.log(`Validation FAILED: Found ${errorCount} errors.`);
        }

    } catch (e) {
        console.error('JSON Syntax Error:', e.message);
    }
}

validateJson();
