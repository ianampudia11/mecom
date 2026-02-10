
const fs = require('fs');
const path = require('path');

const schemaPath = path.resolve(__dirname, '..', 'shared', 'schema.ts');
const content = fs.readFileSync(schemaPath, 'utf8');

const lines = content.split('\n');
const definitions = [
    { name: 'tasks', regex: /export\s+const\s+tasks\s*=/ },
    { name: 'pipelines', regex: /export\s+const\s+pipelines\s*=/ },
    { name: 'deals', regex: /export\s+const\s+deals\s*=/ },
    { name: 'contactTasks', regex: /export\s+const\s+contactTasks\s*=/ },
    { name: 'taskPriorityEnum', regex: /export\s+const\s+taskPriorityEnum\s*=/ },
    { name: 'taskStatusEnum', regex: /export\s+const\s+taskStatusEnum\s*=/ },
    { name: 'taskCategories', regex: /export\s+const\s+taskCategories\s*=/ },
    { name: 'insertTaskSchema', regex: /export\s+const\s+insertTaskSchema\s*=/ },
    { name: 'insertPipelineSchema', regex: /export\s+const\s+insertPipelineSchema\s*=/ },
    { name: 'TaskType', regex: /export\s+type\s+Task\s*=/ }
];

definitions.forEach(def => {
    let count = 0;
    const foundLines = [];
    lines.forEach((line, index) => {
        if (def.regex.test(line)) {
            count++;
            foundLines.push(index + 1);
        }
    });
    console.log(`${def.name}: ${count} occurrences at lines ${foundLines.join(', ')}`);
});
