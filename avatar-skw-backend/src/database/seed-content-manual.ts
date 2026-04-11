
const { Client } = require('pg');
require('dotenv').config();

async function seedContent() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });

    try {
        await client.connect();

        const contents = [
            { key: 'privacy_policy', title: 'Privacy Policy', body: '<h1>Privacy Policy</h1><p>Welcome to our Privacy Policy page. Here we describe how we handle your data.</p>' },
            { key: 'terms_of_service', title: 'Terms of Service', body: '<h1>Terms of Service</h1><p>These are the terms of service for using our application.</p>' },
            { key: 'return_policy', title: 'Return Policy', body: '<h1>Return Policy</h1><p>Details about our return and refund policy.</p>' },
            { key: 'shipping_policy', title: 'Shipping Policy', body: '<h1>Shipping Policy</h1><p>Information regarding shipping and delivery.</p>' }
        ];

        for (const content of contents) {
            const res = await client.query('SELECT id FROM contents WHERE key = $1', [content.key]);
            if (res.rows.length === 0) {
                await client.query(
                    'INSERT INTO contents (key, title, body, "isActive") VALUES ($1, $2, $3, $4)',
                    [content.key, content.title, content.body, true]
                );
                console.log(`Seeded: ${content.title}`);
            } else {
                console.log(`Skipped (already exists): ${content.title}`);
            }
        }

    } catch (err) {
        console.error('Error seeding content', err);
    } finally {
        await client.end();
    }
}

seedContent();
export { };
