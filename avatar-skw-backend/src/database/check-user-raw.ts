
const { Client } = require('pg');
require('dotenv').config();

async function checkUser() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });

    try {
        await client.connect();
        const res = await client.query('SELECT * FROM users WHERE phone = $1', ['9999988888']);

        if (res.rows.length > 0) {
            const user = res.rows[0];
            console.log(`User found: ${user.name}`);
            console.log(`Role: ${user.role}`);
            console.log(`Status: ${user.status}`);
            console.log(`ID: ${user.id}`);
        } else {
            console.log('User not found');
        }
    } catch (err) {
        console.error('Error executing query', err.stack);
    } finally {
        await client.end();
    }
}

checkUser();

export { };
