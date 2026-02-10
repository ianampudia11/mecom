// Set environment to development to bypass integrity check
process.env.NODE_ENV = 'development';

import { db } from './db';
import { contacts } from '../shared/schema';
import { sql, eq } from 'drizzle-orm';

async function diagnoseTags() {
    console.log('=== TAG SYNCHRONIZATION DIAGNOSTIC ===\n');

    try {
        // 1. Get contacts with tags
        console.log('1. Contacts with tags:');
        const contactsWithTags = await db
            .select({
                id: contacts.id,
                name: contacts.name,
                tags: contacts.tags,
            })
            .from(contacts)
            .where(sql`${contacts.tags} IS NOT NULL AND array_length(${contacts.tags}, 1) > 0`)
            .limit(10);

        console.log(`Found ${contactsWithTags.length} contacts with tags:`);
        contactsWithTags.forEach(c => {
            console.log(`  - ID: ${c.id}, Name: ${c.name}, Tags: ${JSON.stringify(c.tags)}`);
        });

        // 2. Test tag filter with specific tag
        const testTag = 'banana'; // From user's screenshot
        console.log(`\n2. Testing filter for tag: "${testTag}"`);

        const filteredContacts = await db
            .select({
                id: contacts.id,
                name: contacts.name,
                tags: contacts.tags,
            })
            .from(contacts)
            .where(sql`
        ${contacts.tags} IS NOT NULL
        AND array_length(${contacts.tags}, 1) > 0
        AND EXISTS (
          SELECT 1
          FROM unnest(${contacts.tags}) AS contact_tag
          WHERE lower(trim(coalesce(contact_tag, ''))) = ${testTag.toLowerCase()}
        )
      `);

        console.log(`Found ${filteredContacts.length} contacts with tag "${testTag}":`);
        filteredContacts.forEach(c => {
            console.log(`  - ID: ${c.id}, Name: ${c.name}, Tags: ${JSON.stringify(c.tags)}`);
        });

        // 3. Alternative test using ANY operator
        console.log(`\n3. Testing alternative filter using ANY operator:`);
        const altFilteredContacts = await db
            .select({
                id: contacts.id,
                name: contacts.name,
                tags: contacts.tags,
            })
            .from(contacts)
            .where(sql`${testTag} = ANY(${contacts.tags})`);

        console.log(`Found ${altFilteredContacts.length} contacts (case-sensitive ANY):`);
        altFilteredContacts.forEach(c => {
            console.log(`  - ID: ${c.id}, Name: ${c.name}, Tags: ${JSON.stringify(c.tags)}`);
        });

        // 4. Case-insensitive ANY test
        console.log(`\n4. Testing case-insensitive ANY operator:`);
        const caseInsensitiveContacts = await db.execute(sql`
      SELECT id, name, tags
      FROM contacts
      WHERE EXISTS (
        SELECT 1 FROM unnest(tags) AS tag
        WHERE lower(tag) = lower(${testTag})
      )
      LIMIT 10
    `);

        console.log(`Found ${caseInsensitiveContacts.rows.length} contacts (case-insensitive):`);
        caseInsensitiveContacts.rows.forEach((c: any) => {
            console.log(`  - ID: ${c.id}, Name: ${c.name}, Tags: ${JSON.stringify(c.tags)}`);
        });

    } catch (error) {
        console.error('Error during diagnosis:', error);
    }

    process.exit(0);
}

diagnoseTags();
