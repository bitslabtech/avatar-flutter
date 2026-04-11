import { Client } from 'pg';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load .env from project root
dotenv.config({ path: path.join(__dirname, '../../.env') });

async function enableSuperAdmin() {
    if (!process.env.DATABASE_URL) {
        console.error('❌ DATABASE_URL is not defined in .env');
        process.exit(1);
    }

    const client = new Client({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });

    try {
        await client.connect();
        console.log('📦 Connected to database via pg');

        const checkRes = await client.query(`
      SELECT id, name, email, role, status 
      FROM users 
      WHERE role = 'super_admin'
    `);

        if (checkRes.rows.length === 0) {
            console.error('❌ No user with role "super_admin" found.');
        } else {
            const user = checkRes.rows[0];
            console.log(`Found Super Admin: ${user.name} (${user.email})`);
            console.log(`Current Status: ${user.status}`);

            if (user.status === 'active') { // Assuming 'active' is the string value for UserStatus.ACTIVE
                console.log('✅ Super Admin is already active.');
            } else {
                const updateRes = await client.query(`
          UPDATE users 
          SET status = 'active' 
          WHERE id = $1
        `, [user.id]);

                console.log(`✅ Super Admin status updated to 'active'. Rows affected: ${updateRes.rowCount}`);
            }
        }
    } catch (err) {
        console.error('❌ Error executing query:', err);
    } finally {
        await client.end();
    }
}

enableSuperAdmin();
