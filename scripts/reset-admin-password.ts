import { storage } from '../server/storage';
import { hashPassword } from '../server/auth';
import { db } from '../server/db';

async function resetAdminPassword() {
    const email = 'admin@ianampudia.com';
    const newPassword = 'admin123';

    console.log(`Resetting password for ${email}...`);

    try {
        const user = await storage.getUserByEmail(email);

        if (!user) {
            console.error(`User with email ${email} not found!`);
            process.exit(1);
        }

        console.log(`Found user ID: ${user.id}`);

        const hashedPassword = await hashPassword(newPassword);

        // Update password and ensure super admin status
        await storage.updateUser(user.id, {
            password: hashedPassword,
            isSuperAdmin: true,
            role: 'super_admin'
        });

        console.log('Password updated successfully!');
        console.log('Super Admin status confirmed.');
        process.exit(0);
    } catch (error) {
        console.error('Error resetting password:', error);
        process.exit(1);
    }
}

resetAdminPassword();
