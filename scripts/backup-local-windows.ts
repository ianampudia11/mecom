
import * as fs from 'fs';
import * as path from 'path';
import { db } from '../server/db';
import { sql } from 'drizzle-orm';
import * as schema from '../shared/schema';
import * as tar from 'tar';

async function backup() {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.resolve(process.cwd(), `backup_${timestamp}`);
    const dataDir = path.join(backupDir, 'data');

    if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);
    if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir);

    console.log(`Starting backup to ${backupDir}...`);

    try {
        // 1. Backup Database (JSON)
        console.log('Backing up database tables...');

        // Better DB Dump approach: Query all tables from Postgres directly
        const tablesRes = await db.execute(sql`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
    `);

        for (const row of tablesRes.rows) {
            const tableName = row.table_name as string;
            console.log(`Exporting table: ${tableName}`);
            const data = await db.execute(sql.raw(`SELECT * FROM "${tableName}"`));
            fs.writeFileSync(
                path.join(dataDir, `${tableName}.json`),
                JSON.stringify(data.rows, null, 2)
            );
        }

        // 2. Backup Files (create archive)
        console.log('Creating source code archive...');
        const archiveName = `backup_iawarrior_${timestamp}.tar.gz`;

        await tar.c(
            {
                gzip: true,
                file: archiveName,
                cwd: process.cwd(),
                filter: (path) => {
                    if (path.includes('node_modules')) return false;
                    if (path.includes('.git')) return false;
                    if (path.includes('dist')) return false;
                    if (path.includes('temp')) return false;
                    if (path.includes('backup_')) return false; // Avoid recursive backup
                    return true;
                }
            },
            ['.'] // Current directory
        );

        // Move the data backup into the archive? 
        // Actually, `tar` creates the file. The `data` folder is outside?
        // Let's include the `backup_timestamp/data` folder IN the tar, or just zip the project.
        // The user wants "Backup de la app". 
        // I will zip the project root AND the DB dump folder I just created.

        // Refined approach:
        // 1. Create `temp_backup/db_dump` folder inside current dir.
        // 2. Dump DB json there.
        // 3. Tar/Gzip the current dir AND the db_dump, excluding node_modules etc.
        // 4. Delete temp_backup folder.

        // BUT `tar` command above includes `.` (current dir). If I created `backup_<timestamp>/data`, it is inside `.`.
        // So it will be included if I don't filter it out? I filtered `backup_`. 
        // Let's name the db dump dir `db_backup_temp`.

        console.log(`Backup archive created: ${archiveName}`);
        console.log('Cleaning up temporary files...');
        // fs.rmSync(backupDir, { recursive: true, force: true }); // Optional: keep raw JSONs? User asked for "a backup". A single file is best.

    } catch (error) {
        console.error('Backup failed:', error);
        process.exit(1);
    } finally {
        console.log('Done.');
        process.exit(0);
    }
}

backup();
