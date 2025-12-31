-- Enable company registration
INSERT INTO app_settings (key, value, created_at, updated_at) 
VALUES (
  'registration_settings', 
  '{"enabled": true, "requireApproval": false}'::jsonb,
  NOW(), 
  NOW()
) 
ON CONFLICT (key) DO UPDATE 
SET value = '{"enabled": true, "requireApproval": false}'::jsonb,
    updated_at = NOW();
