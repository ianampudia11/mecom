import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { storage } from '../storage';
import { pool } from '../db';

const execAsync = promisify(exec);

export interface BackupConfig {
  enabled: boolean;
  schedules: BackupSchedule[];
  retention_days: number;
  storage_locations: string[];
  google_drive: {
    enabled: boolean;
    folder_id: string | null;
    credentials: any;
  };
  encryption: {
    enabled: boolean;
    key: string | null;
  };
}

export interface BackupSchedule {
  id: string;
  frequency: 'daily' | 'weekly' | 'monthly';
  time: string;
  day_of_week?: number;
  day_of_month?: number;
  enabled: boolean;
  storage_locations: string[];
}

export interface BackupRecord {
  id: string;
  filename: string;
  type: 'manual' | 'scheduled';
  description: string;
  size: number;
  created_at: Date;
  status: 'creating' | 'completed' | 'failed' | 'uploading' | 'uploaded';
  storage_locations: string[];
  checksum: string;
  error_message?: string;
  metadata: {
    database_size: number;
    table_count: number;
    row_count: number;
    compression_ratio?: number;
    encryption_enabled: boolean;
  };
}

export class BackupService {
  private backupDir: string;
  private tempDir: string;

  constructor() {
    this.backupDir = path.join(process.cwd(), 'backups');
    this.tempDir = path.join(process.cwd(), 'temp', 'backups');
    this.ensureDirectories();
  }

  private async ensureDirectories(): Promise<void> {
    try {
      await fs.mkdir(this.backupDir, { recursive: true });
      await fs.mkdir(this.tempDir, { recursive: true });
    } catch (error) {
      console.error('Error creating backup directories:', error);
    }
  }

  async createBackup(options: {
    type: 'manual' | 'scheduled';
    description: string;
    storage_locations: string[];
  }): Promise<BackupRecord> {
    const backupId = crypto.randomUUID();
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `powerchat-backup-${timestamp}.sql`;
    const filePath = path.join(this.backupDir, filename);

    const backup: BackupRecord = {
      id: backupId,
      filename,
      type: options.type,
      description: options.description,
      size: 0,
      created_at: new Date(),
      status: 'creating',
      storage_locations: options.storage_locations,
      checksum: '',
      metadata: {
        database_size: 0,
        table_count: 0,
        row_count: 0,
        encryption_enabled: false
      }
    };

    try {
      await this.saveBackupRecord(backup);

      const dbUrl = process.env.DATABASE_URL;
      if (!dbUrl) {
        throw new Error('DATABASE_URL not configured');
      }

      const url = new URL(dbUrl);
      const dbConfig = {
        host: url.hostname,
        port: url.port || '5432',
        database: url.pathname.slice(1),
        username: url.username,
        password: url.password
      };

      const pgDumpCmd = [
        'pg_dump',
        `--host=${dbConfig.host}`,
        `--port=${dbConfig.port}`,
        `--username=${dbConfig.username}`,
        `--dbname=${dbConfig.database}`,
        '--verbose',
        '--clean',
        '--if-exists',
        '--create',
        '--format=custom',
        `--file=${filePath}`
      ].join(' ');

      const env = { ...process.env, PGPASSWORD: dbConfig.password };

      

      const { stdout, stderr } = await execAsync(pgDumpCmd, { env });

     

      const stats = await fs.stat(filePath);
      backup.size = stats.size;

      backup.checksum = await this.calculateChecksum(filePath);

      backup.metadata = await this.getDatabaseMetadata();

      backup.status = 'completed';

      await this.saveBackupRecord(backup);

      await this.handleStorageLocations(backup);

      
      return backup;

    } catch (error) {
      console.error('Error creating backup:', error);
      backup.status = 'failed';
      backup.error_message = error instanceof Error ? error.message : 'Unknown error';
      await this.saveBackupRecord(backup);
      throw error;
    }
  }

  private async calculateChecksum(filePath: string): Promise<string> {
    const fileBuffer = await fs.readFile(filePath);
    return crypto.createHash('sha256').update(fileBuffer).digest('hex');
  }

  private async getDatabaseMetadata(): Promise<BackupRecord['metadata']> {
    try {
      const sizeResult = await pool.query(`
        SELECT pg_size_pretty(pg_database_size(current_database())) as size,
               pg_database_size(current_database()) as size_bytes
      `);

      const tableResult = await pool.query(`
        SELECT COUNT(*) as count
        FROM information_schema.tables
        WHERE table_schema = 'public'
      `);

      const rowResult = await pool.query(`
        SELECT SUM(n_tup_ins + n_tup_upd) as total_rows
        FROM pg_stat_user_tables
      `);

      return {
        database_size: parseInt(sizeResult.rows[0]?.size_bytes || '0'),
        table_count: parseInt(tableResult.rows[0]?.count || '0'),
        row_count: parseInt(rowResult.rows[0]?.total_rows || '0'),
        encryption_enabled: false
      };
    } catch (error) {
      console.error('Error getting database metadata:', error);
      return {
        database_size: 0,
        table_count: 0,
        row_count: 0,
        encryption_enabled: false
      };
    }
  }

  private async handleStorageLocations(backup: BackupRecord): Promise<void> {
    for (const location of backup.storage_locations) {
      if (location === 'google_drive') {
        try {
          backup.status = 'uploading';
          await this.saveBackupRecord(backup);

          const { GoogleDriveService } = await import('./google-drive-service');
          const googleDriveService = new GoogleDriveService();

          const filePath = path.join(this.backupDir, backup.filename);
          await googleDriveService.uploadBackup(filePath, backup.filename);

          backup.status = 'uploaded';
          await this.saveBackupRecord(backup);
        } catch (error) {
          console.error('Error uploading to Google Drive:', error);
          backup.error_message = `Google Drive upload failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
          await this.saveBackupRecord(backup);
        }
      }
    }
  }

  private async saveBackupRecord(backup: BackupRecord): Promise<void> {
    try {
      const backups = await this.getBackupRecords();
      const existingIndex = backups.findIndex(b => b.id === backup.id);

      if (existingIndex >= 0) {
        backups[existingIndex] = backup;
      } else {
        backups.push(backup);
      }

      await storage.saveAppSetting('backup_records', backups);
    } catch (error) {
      console.error('Error saving backup record:', error);
    }
  }

  private async getBackupRecords(): Promise<BackupRecord[]> {
    try {
      const setting = await storage.getAppSetting('backup_records');
      return (setting?.value as BackupRecord[]) || [];
    } catch (error) {
      console.error('Error getting backup records:', error);
      return [];
    }
  }

  async listBackups(): Promise<BackupRecord[]> {
    const records = await this.getBackupRecords();

    return records.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
  }

  async getBackup(id: string): Promise<BackupRecord | null> {
    const records = await this.getBackupRecords();
    return records.find(r => r.id === id) || null;
  }

  async getBackupFilePath(backup: BackupRecord): Promise<string> {
    return path.join(this.backupDir, backup.filename);
  }

  async deleteBackup(id: string): Promise<void> {
    const backup = await this.getBackup(id);
    if (!backup) {
      throw new Error('Backup not found');
    }

    try {
      const filePath = path.join(this.backupDir, backup.filename);
      try {
        await fs.unlink(filePath);
      } catch (error) {
        
      }

      if (backup.storage_locations.includes('google_drive')) {
        try {
          const { GoogleDriveService } = await import('./google-drive-service');
          const googleDriveService = new GoogleDriveService();
          await googleDriveService.deleteBackup(backup.filename);
        } catch (error) {
          
        }
      }

      const records = await this.getBackupRecords();
      const filteredRecords = records.filter(r => r.id !== id);
      await storage.saveAppSetting('backup_records', filteredRecords);

    } catch (error) {
      console.error('Error deleting backup:', error);
      throw error;
    }
  }

  async restoreBackup(id: string, options?: {
    userId?: number;
    userEmail?: string;
    confirmationText?: string;
  }): Promise<{
    success: boolean;
    message: string;
    details?: any;
    restoreId?: string;
  }> {
    const restoreId = crypto.randomUUID();
    const startTime = Date.now();

    await this.logRestoreAttempt(restoreId, id, 'started', options?.userId, options?.userEmail);

    const backup = await this.getBackup(id);
    if (!backup) {
      await this.logRestoreAttempt(restoreId, id, 'failed', options?.userId, options?.userEmail, 'Backup not found');
      throw new Error('Backup not found');
    }

    if (backup.status === 'creating' || backup.status === 'failed') {
      const errorMsg = `Cannot restore backup with status: ${backup.status}`;
      await this.logRestoreAttempt(restoreId, id, 'failed', options?.userId, options?.userEmail, errorMsg);
      return {
        success: false,
        message: errorMsg,
        restoreId
      };
    }

    try {
      

      const filePath = path.join(this.backupDir, backup.filename);

      let fileDownloaded = false;
      try {
        await fs.access(filePath);
        
      } catch (error) {
        if (backup.storage_locations.includes('google_drive')) {
          
          const { GoogleDriveService } = await import('./google-drive-service');
          const googleDriveService = new GoogleDriveService();
          await googleDriveService.downloadBackup(backup.filename, filePath);
          fileDownloaded = true;
          
        } else {
          throw new Error('Backup file not found locally or in cloud storage');
        }
      }

      
      const verificationResult = await this.verifyBackup(id);
      if (!verificationResult.valid) {
        const errorMsg = `Backup verification failed: ${verificationResult.message}`;
        await this.logRestoreAttempt(restoreId, id, 'failed', options?.userId, options?.userEmail, errorMsg);
        return {
          success: false,
          message: errorMsg,
          restoreId
        };
      }
      

      const currentMetadata = await this.getDatabaseMetadata();

      const dbUrl = process.env.DATABASE_URL;
      if (!dbUrl) {
        throw new Error('DATABASE_URL not configured');
      }

      const url = new URL(dbUrl);
      const dbConfig = {
        host: url.hostname,
        port: url.port || '5432',
        database: url.pathname.slice(1),
        username: url.username,
        password: url.password
      };

      const pgRestoreCmd = [
        'pg_restore',
        `--host=${dbConfig.host}`,
        `--port=${dbConfig.port}`,
        `--username=${dbConfig.username}`,
        `--dbname=${dbConfig.database}`,
        '--verbose',
        '--clean',
        '--if-exists',
        '--no-owner',
        '--no-privileges',
        '--single-transaction',
        filePath
      ].join(' ');

      const env = { ...process.env, PGPASSWORD: dbConfig.password };

      

      const restorePromise = execAsync(pgRestoreCmd, {
        env,
        timeout: 30 * 60 * 1000
      });

      const { stdout, stderr } = await restorePromise;

      if (stderr && !stderr.includes('NOTICE:') && !stderr.includes('WARNING:')) {
        
      }

      const executionTime = Date.now() - startTime;

      const restoredMetadata = await this.getDatabaseMetadata();

      const restoreDetails = {
        backup_id: backup.id,
        backup_filename: backup.filename,
        backup_created_at: backup.created_at,
        backup_size: backup.size,
        execution_time_ms: executionTime,
        file_downloaded: fileDownloaded,
        pre_restore_metadata: currentMetadata,
        post_restore_metadata: restoredMetadata,
        verification_passed: true,
        confirmation_text: options?.confirmationText
      };

      await this.logRestoreAttempt(restoreId, id, 'success', options?.userId, options?.userEmail, undefined, restoreDetails);

      

      return {
        success: true,
        message: `Database restored successfully from backup "${backup.filename}" created on ${new Date(backup.created_at).toLocaleString()}`,
        details: restoreDetails,
        restoreId
      };

    } catch (error) {
      const executionTime = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error during restore';

      console.error('Error restoring backup:', error);

      await this.logRestoreAttempt(restoreId, id, 'failed', options?.userId, options?.userEmail, errorMessage, {
        backup_id: backup.id,
        backup_filename: backup.filename,
        execution_time_ms: executionTime,
        error_details: error instanceof Error ? error.stack : String(error)
      });

      return {
        success: false,
        message: errorMessage,
        restoreId
      };
    }
  }

  private async logRestoreAttempt(
    restoreId: string,
    backupId: string,
    status: 'started' | 'success' | 'failed',
    userId?: number,
    userEmail?: string,
    errorMessage?: string,
    metadata?: any
  ): Promise<void> {
    try {
      const logs = await this.getBackupLogs();

      const logEntry = {
        id: crypto.randomUUID(),
        schedule_id: 'restore',
        backup_id: backupId,
        status: status === 'started' ? 'success' : status,
        timestamp: new Date().toISOString(),
        error_message: errorMessage,
        metadata: {
          restore_id: restoreId,
          restore_status: status,
          user_id: userId,
          user_email: userEmail,
          ...metadata
        }
      };

      logs.push(logEntry);

      if (logs.length > 200) {
        logs.splice(0, logs.length - 200);
      }

      await storage.saveAppSetting('backup_logs', logs);

      
    } catch (error) {
      console.error('Error logging restore attempt:', error);
    }
  }

  private async getBackupLogs(): Promise<Array<{
    id: string;
    schedule_id: string;
    backup_id: string | null;
    status: 'success' | 'failed';
    timestamp: string;
    error_message?: string;
    metadata?: any;
  }>> {
    try {
      const setting = await storage.getAppSetting('backup_logs');
      return (setting?.value as Array<{
        id: string;
        schedule_id: string;
        backup_id: string | null;
        status: 'success' | 'failed';
        timestamp: string;
        error_message?: string;
        metadata?: any;
      }>) || [];
    } catch (error) {
      console.error('Error getting backup logs:', error);
      return [];
    }
  }

  async processUploadedBackup(options: {
    filePath: string;
    originalName: string;
    filename: string;
    size: number;
    description: string;
    storage_locations: string[];
  }): Promise<BackupRecord> {
    const backupId = crypto.randomUUID();

    const backup: BackupRecord = {
      id: backupId,
      filename: options.filename,
      type: 'manual',
      description: options.description,
      size: options.size,
      created_at: new Date(),
      status: 'creating',
      storage_locations: options.storage_locations,
      checksum: '',
      metadata: {
        database_size: 0,
        table_count: 0,
        row_count: 0,
        encryption_enabled: false
      }
    };

    try {
      backup.checksum = await this.calculateChecksum(options.filePath);

      const isValid = await this.validateBackupFile(options.filePath);
      if (!isValid) {
        throw new Error('Invalid backup file format. Please upload a valid PostgreSQL backup file.');
      }

      backup.status = 'completed';

      await this.saveBackupRecord(backup);

      await this.handleStorageLocations(backup);

      
      return backup;

    } catch (error) {
      console.error('Error processing uploaded backup:', error);
      backup.status = 'failed';
      backup.error_message = error instanceof Error ? error.message : 'Unknown error';
      await this.saveBackupRecord(backup);

      try {
        await fs.unlink(options.filePath);
      } catch (cleanupError) {
        console.error('Error cleaning up failed upload:', cleanupError);
      }

      throw error;
    }
  }

  private async validateBackupFile(filePath: string): Promise<boolean> {
    try {
      const ext = path.extname(filePath).toLowerCase();
      const validExtensions = ['.sql', '.backup', '.dump', '.bak'];
      if (!validExtensions.includes(ext)) {
        return false;
      }

      if (ext === '.sql') {
        const fileContent = await fs.readFile(filePath, 'utf8');
        return fileContent.includes('PostgreSQL database dump') ||
               fileContent.includes('pg_dump') ||
               fileContent.includes('CREATE TABLE') ||
               fileContent.includes('INSERT INTO');
      }

      try {
        const pgListCmd = `pg_restore --list "${filePath}"`;
        await execAsync(pgListCmd);
        return true;
      } catch (error) {
        return false;
      }

    } catch (error) {
      console.error('Error validating backup file:', error);
      return false;
    }
  }

  async verifyBackup(id: string): Promise<{ valid: boolean; message: string; details?: any }> {
    const backup = await this.getBackup(id);
    if (!backup) {
      throw new Error('Backup not found');
    }

    try {
      const filePath = path.join(this.backupDir, backup.filename);

      try {
        await fs.access(filePath);
      } catch (error) {
        return {
          valid: false,
          message: 'Backup file not found locally'
        };
      }

      const stats = await fs.stat(filePath);
      if (stats.size !== backup.size) {
        return {
          valid: false,
          message: `File size mismatch. Expected: ${backup.size}, Actual: ${stats.size}`
        };
      }

      const currentChecksum = await this.calculateChecksum(filePath);
      if (currentChecksum !== backup.checksum) {
        return {
          valid: false,
          message: 'Checksum verification failed. File may be corrupted.'
        };
      }

      const pgListCmd = `pg_restore --list "${filePath}"`;

      try {
        const { stdout } = await execAsync(pgListCmd);
        const tableCount = (stdout.match(/TABLE/g) || []).length;

        return {
          valid: true,
          message: 'Backup verification successful',
          details: {
            file_size: stats.size,
            checksum_valid: true,
            table_count: tableCount,
            backup_format: 'PostgreSQL custom format'
          }
        };
      } catch (error) {
        return {
          valid: false,
          message: 'Backup file format verification failed'
        };
      }

    } catch (error) {
      console.error('Error verifying backup:', error);
      return {
        valid: false,
        message: error instanceof Error ? error.message : 'Unknown error during verification'
      };
    }
  }

  async getBackupStats(): Promise<{
    total_backups: number;
    total_size: number;
    local_backups: number;
    cloud_backups: number;
    oldest_backup: Date | null;
    newest_backup: Date | null;
    storage_usage: {
      local: number;
      google_drive: number;
    };
  }> {
    try {
      const backups = await this.getBackupRecords();

      const totalSize = backups.reduce((sum, backup) => sum + backup.size, 0);
      const localBackups = backups.filter(b => b.storage_locations.includes('local')).length;
      const cloudBackups = backups.filter(b => b.storage_locations.includes('google_drive')).length;

      const dates = backups.map(b => new Date(b.created_at));
      const oldestBackup = dates.length > 0 ? new Date(Math.min(...dates.map(d => d.getTime()))) : null;
      const newestBackup = dates.length > 0 ? new Date(Math.max(...dates.map(d => d.getTime()))) : null;

      const localSize = backups
        .filter(b => b.storage_locations.includes('local'))
        .reduce((sum, backup) => sum + backup.size, 0);

      const cloudSize = backups
        .filter(b => b.storage_locations.includes('google_drive'))
        .reduce((sum, backup) => sum + backup.size, 0);

      return {
        total_backups: backups.length,
        total_size: totalSize,
        local_backups: localBackups,
        cloud_backups: cloudBackups,
        oldest_backup: oldestBackup,
        newest_backup: newestBackup,
        storage_usage: {
          local: localSize,
          google_drive: cloudSize
        }
      };
    } catch (error) {
      console.error('Error getting backup stats:', error);
      return {
        total_backups: 0,
        total_size: 0,
        local_backups: 0,
        cloud_backups: 0,
        oldest_backup: null,
        newest_backup: null,
        storage_usage: {
          local: 0,
          google_drive: 0
        }
      };
    }
  }

  async cleanupOldBackups(retentionDays: number = 30): Promise<{ deleted: number; errors: string[] }> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    const backups = await this.getBackupRecords();
    const oldBackups = backups.filter(backup =>
      new Date(backup.created_at) < cutoffDate
    );

    let deleted = 0;
    const errors: string[] = [];

    for (const backup of oldBackups) {
      try {
        await this.deleteBackup(backup.id);
        deleted++;
        
      } catch (error) {
        const errorMsg = `Failed to delete backup ${backup.filename}: ${error instanceof Error ? error.message : 'Unknown error'}`;
        errors.push(errorMsg);
        console.error(errorMsg);
      }
    }

    return { deleted, errors };
  }
}
