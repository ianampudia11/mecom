-- Crear deals de prueba
INSERT INTO deals (company_id, contact_id, title, stage_id, stage, value, priority, status, description, tags, last_activity_at, created_at, updated_at)
SELECT 
    1 as company_id,
    c.id as contact_id,
    'Interesado en ' || c.full_name as title,
    1 as stage_id,
    'lead' as stage,
    FLOOR(RANDOM() * 50000 + 10000) as value,
    CASE WHEN RANDOM() < 0.33 THEN 'low' WHEN RANDOM() < 0.66 THEN 'medium' ELSE 'high' END as priority,
    'active' as status,
    'Deal creado automáticamente para pruebas' as description,
    ARRAY['test', 'automated'] as tags,
    NOW() as last_activity_at,
    NOW() as created_at,
    NOW() as updated_at
FROM contacts c
WHERE c.company_id = 1
LIMIT 3;

-- Crear tasks de prueba
INSERT INTO tasks (company_id, title, description, status, priority, due_date, assigned_to_user_id, created_at, updated_at)
VALUES 
    (1, 'Llamar a cliente potencial', 'Seguimiento de lead interesado en propiedad del centro', 'pending', 'high', NOW() + INTERVAL '2 days', NULL, NOW(), NOW()),
    (1, 'Enviar cotización', 'Preparar y enviar cotización para casa en zona norte', 'pending', 'medium', NOW() + INTERVAL '3 days', NULL, NOW(), NOW()),
    (1, 'Agendar visita', 'Coordinar visita a propiedad con cliente', 'pending', 'high', NOW() + INTERVAL '1 day', NULL, NOW(), NOW()),
    (1, 'Revisar documentos', 'Verificar documentación legal de propiedad', 'in_progress', 'medium', NOW() + INTERVAL '5 days', NULL, NOW(), NOW()),
    (1, 'Preparar contrato', 'Elaborar borrador de contrato de compraventa', 'pending', 'low', NOW() + INTERVAL '7 days', NULL, NOW(), NOW());

-- Verificar resultados
SELECT 'Deals creados:' as info, COUNT(*) as count FROM deals;
SELECT 'Tasks creados:' as info, COUNT(*) as count FROM tasks;
