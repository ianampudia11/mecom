import { scrypt, randomBytes } from 'crypto';
import { promisify } from 'util';
import { pool } from '../server/db.js';

const scryptAsync = promisify(scrypt);

async function createAdminUser() {
    const email = 'admin@admin.com';
    const password = 'admin123';

    // Generate password hash using scrypt (same as the app)
    const salt = randomBytes(16).toString('hex');
    const derivedKey = await scryptAsync(password, salt, 64) as Buffer;
    // Format: hashedPassword.salt (same as auth.ts hashPassword function)
    const passwordHash = `${derivedKey.toString('hex')}.${salt}`;

    console.log('Creating admin user...');
    console.log('Email:', email);
    console.log('Password:', password);

    try {
        // Insert admin user
        await pool.query(`
      INSERT INTO users (email, username, password, full_name, is_super_admin, company_id)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [email, 'superadmin', passwordHash, 'Super Admin', true, 1]);

        console.log('✅ Admin user created successfully!');
        console.log('You can now login with:');
        console.log('  Email:', email);
        console.log('  Password:', password);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating admin user:', error);
        process.exit(1);
    }
}

createAdminUser();
