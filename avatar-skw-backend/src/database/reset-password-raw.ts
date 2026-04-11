
const { Client } = require('pg');
require('dotenv').config();

async function getHash() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });

    try {
        await client.connect();
        // Get hash from superadmin
        const res = await client.query('SELECT password_hash FROM users WHERE phone = $1', ['9999000001']);

        if (res.rows.length > 0) {
            const hash = res.rows[0].password_hash;
            console.log(`Hash found: ${hash}`);

            // Update Manish's password
            await client.query('UPDATE users SET password_hash = $1 WHERE phone = $2', [hash, '9999988888']);
            console.log('✅ Password updated for 9999988888 to Password@123');
        } else {
            console.log('Superadmin not found to copy hash');
        }
    } catch (err) {
        console.error('Error', err.stack);
    } finally {
        await client.end();
    }
}

getHash();

export { };
