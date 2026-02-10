import { db } from '../../../db';
import { conversations, deals, contacts } from '@shared/schema';
import { sql, eq, and } from 'drizzle-orm';

/**
 * Repository for tag statistics and management
 */

// Get only manually created tags from tags table
export async function getManualTags(companyId: number) {
  try {
    const result = await db.execute(sql`
      SELECT id, tag, color, created_at, updated_at
      FROM tags
      WHERE company_id = ${companyId}
      ORDER BY tag ASC
    `);
    return result.rows || [];
  } catch (error) {
    console.error('Error getting manual tags:', error);
    return [];
  }
}

export async function getTagStats(companyId: number) {
  try {
    // Get tags from conversations
    const conversationsResult = await db.execute(sql`
      SELECT 
        tag,
        COUNT(*) as count
      FROM (
        SELECT unnest(tags) as tag
        FROM conversations
        WHERE company_id = ${companyId}
          AND tags IS NOT NULL
          AND array_length(tags, 1) > 0
      ) conv_tags
      GROUP BY tag
    `);

    // Get tags from deals
    const dealsResult = await db.execute(sql`
      SELECT 
        tag,
        COUNT(*) as count
      FROM (
        SELECT unnest(tags) as tag
        FROM deals
        WHERE company_id = ${companyId}
          AND tags IS NOT NULL
          AND array_length(tags, 1) > 0
      ) deal_tags
      GROUP BY tag
    `);

    // Get tags from contacts
    const contactsResult = await db.execute(sql`
      SELECT 
        tag,
        COUNT(*) as count
      FROM (
        SELECT unnest(tags) as tag
        FROM contacts
        WHERE company_id = ${companyId}
          AND tags IS NOT NULL
          AND array_length(tags, 1) > 0
          AND is_active = true
      ) contact_tags
      GROUP BY tag
    `);

    // Get manually created tags (may not exist yet)
    let manualTags: any = { rows: [] };
    try {
      manualTags = await db.execute(sql`
        SELECT tag as tag, color
        FROM tags
        WHERE company_id = ${companyId}
      `);
    } catch (error: any) {
      // Table might not exist yet - that's ok, just use empty array
      if (error.code !== '42P01' && error.code !== '42703') {
        // Re-throw if it's not a "table/column doesn't exist" error
        throw error;
      }
    }

    // Combine results
    const statsMap = new Map();

    (conversationsResult.rows as any[]).forEach((row: any) => {
      statsMap.set(row.tag, {
        tag: row.tag,
        conversationCount: parseInt(row.count),
        dealCount: 0,
        contactCount: 0,
        color: null
      });
    });

    (dealsResult.rows as any[]).forEach((row: any) => {
      const existing = statsMap.get(row.tag);
      if (existing) {
        existing.dealCount = parseInt(row.count);
      } else {
        statsMap.set(row.tag, {
          tag: row.tag,
          conversationCount: 0,
          dealCount: parseInt(row.count),
          contactCount: 0,
          color: null
        });
      }
    });

    (contactsResult.rows as any[]).forEach((row: any) => {
      const existing = statsMap.get(row.tag);
      if (existing) {
        existing.contactCount = parseInt(row.count);
      } else {
        statsMap.set(row.tag, {
          tag: row.tag,
          conversationCount: 0,
          dealCount: 0,
          contactCount: parseInt(row.count),
          color: null
        });
      }
    });

    // Add colors from manual tags
    (manualTags.rows as any[]).forEach((row: any) => {
      const existing = statsMap.get(row.tag);
      if (existing) {
        existing.color = row.color;
      } else {
        statsMap.set(row.tag, {
          tag: row.tag,
          conversationCount: 0,
          dealCount: 0,
          contactCount: 0,
          color: row.color
        });
      }
    });

    return Array.from(statsMap.values()).sort((a, b) => a.tag.localeCompare(b.tag));
  } catch (error) {
    console.error('Error getting tag stats:', error);
    return [];
  }
}

// Helper to validate hex color
function validateColor(color?: string): string | null {
  if (!color) return null;
  // Remove whitespace and validate hex format
  const trimmed = color.trim();
  if (!/^#[0-9A-F]{6}$/i.test(trimmed)) {
    throw new Error('Color must be a valid hex format (#RRGGBB)');
  }
  return trimmed.toUpperCase();
}

export async function createTag(companyId: number, name: string, color?: string) {
  try {
    // Validate color format
    const validatedColor = validateColor(color);

    // Ensure tags table exists
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS tags (
        id SERIAL PRIMARY KEY,
        company_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        color TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(company_id, tag)
      )
    `);

    // Check if tag already exists
    const existing = await db.execute(sql`
      SELECT 1 FROM tags WHERE company_id = ${companyId} AND tag = ${name}
      UNION
      SELECT 1 FROM conversations WHERE company_id = ${companyId} AND ${name} = ANY(tags)
      UNION
      SELECT 1 FROM deals WHERE company_id = ${companyId} AND ${name} = ANY(tags)
      UNION
      SELECT 1 FROM contacts WHERE company_id = ${companyId} AND ${name} = ANY(tags)
      LIMIT 1
    `);

    if (existing.rows.length > 0) {
      throw new Error('Tag already exists');
    }

    await db.execute(sql`
      INSERT INTO tags (company_id, tag, color)
      VALUES (${companyId}, ${name}, ${validatedColor})
    `);

    return { tag: name, color: validatedColor };
  } catch (error) {
    console.error('Error creating tag:', error);
    throw error;
  }
}

export async function renameTag(companyId: number, oldName: string, newName: string, color?: string) {
  try {
    // Validate color format
    const validatedColor = validateColor(color);

    // Ensure tags table exists with correct schema
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS tags (
        id SERIAL PRIMARY KEY,
        company_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        color TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(company_id, tag)
      )
    `);

    // Migrate old 'name' column to 'tag' if it exists
    await db.execute(sql`
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='tags' AND column_name='name'
        ) THEN
          ALTER TABLE tags RENAME COLUMN name TO tag;
        END IF;
      END $$;
    `);

    // Add missing columns if they don't exist
    await db.execute(sql`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='tags' AND column_name='created_at'
        ) THEN
          ALTER TABLE tags ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        END IF;
        
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='tags' AND column_name='updated_at'
        ) THEN
          ALTER TABLE tags ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        END IF;
      END $$;
    `);

    // Update in all tables
    await db.execute(sql`
      UPDATE conversations
      SET tags = array_remove(tags, ${oldName}) || ARRAY[${newName}]
      WHERE company_id = ${companyId} AND ${oldName} = ANY(tags)
    `);

    await db.execute(sql`
      UPDATE deals
      SET tags = array_remove(tags, ${oldName}) || ARRAY[${newName}]
      WHERE company_id = ${companyId} AND ${oldName} = ANY(tags)
    `);

    await db.execute(sql`
      UPDATE contacts
      SET tags = array_remove(tags, ${oldName}) || ARRAY[${newName}]
      WHERE company_id = ${companyId} AND ${oldName} = ANY(tags)
    `);

    // Upsert in tags table
    await db.execute(sql`
      INSERT INTO tags (company_id, tag, color)
      VALUES (${companyId}, ${newName}, ${validatedColor})
      ON CONFLICT (company_id, tag) 
      DO UPDATE SET color = ${validatedColor}, updated_at = CURRENT_TIMESTAMP
    `);

    // Delete old tag if name changed
    if (oldName !== newName) {
      await db.execute(sql`
        DELETE FROM tags WHERE company_id = ${companyId} AND tag = ${oldName}
      `);
    }

    return { oldTag: oldName, newTag: newName, color: validatedColor };
  } catch (error) {
    console.error('Error renaming tag:', error);
    throw error;
  }
}

export async function deleteTag(companyId: number, tagName: string) {
  try {
    // Remove from all tables
    await db.execute(sql`
      UPDATE conversations SET tags = array_remove(tags, ${tagName})
      WHERE company_id = ${companyId} AND ${tagName} = ANY(tags)
    `);

    await db.execute(sql`
      UPDATE deals SET tags = array_remove(tags, ${tagName})
      WHERE company_id = ${companyId} AND ${tagName} = ANY(tags)
    `);

    await db.execute(sql`
      UPDATE contacts SET tags = array_remove(tags, ${tagName})
      WHERE company_id = ${companyId} AND ${tagName} = ANY(tags)
    `);

    await db.execute(sql`
      DELETE FROM tags WHERE company_id = ${companyId} AND tag = ${tagName}
    `);

    return true;
  } catch (error) {
    console.error('Error deleting tag:', error);
    return false;
  }
}
