-- Emergency Restoration Migration
-- Timestamp: 2026-01-06
-- Description: Ensures ALL tables and constraints exist based on healthy local DB.

-- Ensure Enums exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'agent'); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'update_status') THEN CREATE TYPE update_status AS ENUM ('pending', 'downloading', 'validating', 'applying', 'completed', 'failed', 'rolled_back'); END IF;
END $$;


-- Table: plans
CREATE TABLE IF NOT EXISTS "plans" (
  "id" integer NOT NULL DEFAULT nextval('plans_id_seq'::regclass),
  "name" text NOT NULL,
  "description" text,
  "price" numeric NOT NULL DEFAULT 0,
  "max_users" integer NOT NULL DEFAULT 5,
  "max_contacts" integer NOT NULL DEFAULT 1000,
  "max_channels" integer NOT NULL DEFAULT 3,
  "max_flows" integer NOT NULL DEFAULT 1,
  "max_campaigns" integer NOT NULL DEFAULT 5,
  "max_campaign_recipients" integer NOT NULL DEFAULT 1000,
  "campaign_features" jsonb NOT NULL DEFAULT '["basic_campaigns"]'::jsonb,
  "is_active" boolean NOT NULL DEFAULT true,
  "is_free" boolean NOT NULL DEFAULT false,
  "has_trial_period" boolean NOT NULL DEFAULT false,
  "trial_days" integer DEFAULT 0,
  "features" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "discount_type" text DEFAULT 'none'::text,
  "discount_value" numeric DEFAULT 0,
  "discount_duration" text DEFAULT 'permanent'::text,
  "discount_start_date" timestamp without time zone,
  "discount_end_date" timestamp without time zone,
  "original_price" numeric,
  "ai_tokens_included" integer DEFAULT 0,
  "ai_tokens_monthly_limit" integer,
  "ai_tokens_daily_limit" integer,
  "ai_overage_enabled" boolean DEFAULT false,
  "ai_overage_rate" numeric DEFAULT 0.000000,
  "ai_overage_block_enabled" boolean DEFAULT false,
  "ai_billing_enabled" boolean DEFAULT false,
  "billing_interval" text DEFAULT 'month'::text,
  "grace_period_days" integer DEFAULT 3,
  "max_dunning_attempts" integer DEFAULT 3,
  "soft_limit_percentage" integer DEFAULT 80,
  "allow_pausing" boolean DEFAULT true,
  "pause_max_days" integer DEFAULT 90,
  "storage_limit" integer DEFAULT 1024,
  "bandwidth_limit" integer DEFAULT 10240,
  "file_upload_limit" integer DEFAULT 25,
  "total_files_limit" integer DEFAULT 1000,
  "custom_duration_days" integer,
  PRIMARY KEY ("id")
);

-- Table: contacts
CREATE TABLE IF NOT EXISTS "contacts" (
  "id" integer NOT NULL DEFAULT nextval('contacts_id_seq'::regclass),
  "company_id" integer,
  "name" text NOT NULL,
  "avatar_url" text,
  "email" text,
  "phone" text,
  "company" text,
  "tags" text[],
  "is_active" boolean DEFAULT true,
  "identifier" text,
  "identifier_type" text,
  "source" text,
  "notes" text,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  "is_history_sync" boolean DEFAULT false,
  "history_sync_batch_id" text,
  "is_archived" boolean NOT NULL DEFAULT false,
  "assigned_to_user_id" integer,
  PRIMARY KEY ("id")
);

-- Table: role_permissions
CREATE TABLE IF NOT EXISTS "role_permissions" (
  "id" integer NOT NULL DEFAULT nextval('role_permissions_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "role" user_role NOT NULL,
  "permissions" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: conversations
CREATE TABLE IF NOT EXISTS "conversations" (
  "id" integer NOT NULL DEFAULT nextval('conversations_id_seq'::regclass),
  "company_id" integer,
  "contact_id" integer,
  "channel_type" text NOT NULL,
  "channel_id" integer NOT NULL,
  "status" text DEFAULT 'open'::text,
  "assigned_to_user_id" integer,
  "last_message_at" timestamp without time zone DEFAULT now(),
  "unread_count" integer DEFAULT 0,
  "bot_disabled" boolean DEFAULT false,
  "disabled_at" timestamp without time zone,
  "disable_duration" integer,
  "disable_reason" text,
  "is_group" boolean DEFAULT false,
  "group_jid" text,
  "group_name" text,
  "group_description" text,
  "group_participant_count" integer DEFAULT 0,
  "group_created_at" timestamp without time zone,
  "group_metadata" jsonb,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  "is_history_sync" boolean DEFAULT false,
  "history_sync_batch_id" text,
  "is_starred" boolean DEFAULT false,
  "is_archived" boolean DEFAULT false,
  "archived_at" timestamp without time zone,
  "starred_at" timestamp without time zone,
  "tags" text[],
  PRIMARY KEY ("id")
);

-- Table: companies
CREATE TABLE IF NOT EXISTS "companies" (
  "id" integer NOT NULL DEFAULT nextval('companies_id_seq'::regclass),
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "subdomain" text,
  "logo" text,
  "primary_color" text DEFAULT '#363636'::text,
  "active" boolean DEFAULT true,
  "plan" text DEFAULT 'free'::text,
  "plan_id" integer,
  "subscription_status" text NOT NULL DEFAULT 'inactive'::text,
  "subscription_start_date" timestamp without time zone,
  "subscription_end_date" timestamp without time zone,
  "trial_start_date" timestamp without time zone,
  "trial_end_date" timestamp without time zone,
  "is_in_trial" boolean DEFAULT false,
  "max_users" integer DEFAULT 5,
  "register_number" text,
  "company_email" text,
  "contact_person" text,
  "iban" text,
  "stripe_customer_id" text,
  "stripe_subscription_id" text,
  "billing_cycle_anchor" timestamp without time zone,
  "grace_period_end" timestamp without time zone,
  "pause_start_date" timestamp without time zone,
  "pause_end_date" timestamp without time zone,
  "auto_renewal" boolean NOT NULL DEFAULT true,
  "dunning_attempts" integer DEFAULT 0,
  "last_dunning_attempt" timestamp without time zone,
  "subscription_metadata" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "current_storage_used" integer DEFAULT 0,
  "current_bandwidth_used" integer DEFAULT 0,
  "files_count" integer DEFAULT 0,
  "last_usage_update" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: users
CREATE TABLE IF NOT EXISTS "users" (
  "id" integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  "username" text NOT NULL,
  "password" text NOT NULL,
  "full_name" text NOT NULL,
  "email" text NOT NULL,
  "avatar_url" text,
  "role" user_role DEFAULT 'agent'::user_role,
  "company_id" integer,
  "is_super_admin" boolean DEFAULT false,
  "active" boolean DEFAULT true,
  "language_preference" text DEFAULT 'en'::text,
  "permissions" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  "mobile_phone" text,
  "notification_preferences" jsonb DEFAULT '{"email": true, "whatsapp": false}'::jsonb,
  PRIMARY KEY ("id")
);

-- Table: group_participants
CREATE TABLE IF NOT EXISTS "group_participants" (
  "id" integer NOT NULL DEFAULT nextval('group_participants_id_seq'::regclass),
  "conversation_id" integer NOT NULL,
  "contact_id" integer,
  "participant_jid" text NOT NULL,
  "participant_name" text,
  "is_admin" boolean DEFAULT false,
  "is_super_admin" boolean DEFAULT false,
  "joined_at" timestamp without time zone DEFAULT now(),
  "left_at" timestamp without time zone,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: notes
CREATE TABLE IF NOT EXISTS "notes" (
  "id" integer NOT NULL DEFAULT nextval('notes_id_seq'::regclass),
  "contact_id" integer NOT NULL,
  "created_by_id" integer NOT NULL,
  "content" text NOT NULL,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flows
CREATE TABLE IF NOT EXISTS "flows" (
  "id" integer NOT NULL DEFAULT nextval('flows_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "company_id" integer,
  "name" text NOT NULL,
  "description" text,
  "status" text NOT NULL DEFAULT 'draft'::text,
  "nodes" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "edges" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "version" integer NOT NULL DEFAULT 1,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flow_assignments
CREATE TABLE IF NOT EXISTS "flow_assignments" (
  "id" integer NOT NULL DEFAULT nextval('flow_assignments_id_seq'::regclass),
  "flow_id" integer NOT NULL,
  "channel_id" integer NOT NULL,
  "is_active" boolean NOT NULL DEFAULT false,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flow_executions
CREATE TABLE IF NOT EXISTS "flow_executions" (
  "id" integer NOT NULL DEFAULT nextval('flow_executions_id_seq'::regclass),
  "execution_id" text NOT NULL,
  "flow_id" integer NOT NULL,
  "conversation_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "company_id" integer,
  "status" text NOT NULL DEFAULT 'running'::text,
  "trigger_node_id" text NOT NULL,
  "current_node_id" text,
  "execution_path" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "context_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "started_at" timestamp without time zone NOT NULL DEFAULT now(),
  "completed_at" timestamp without time zone,
  "last_activity_at" timestamp without time zone NOT NULL DEFAULT now(),
  "total_duration_ms" integer,
  "completion_rate" numeric,
  "error_message" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flow_sessions
CREATE TABLE IF NOT EXISTS "flow_sessions" (
  "id" integer NOT NULL DEFAULT nextval('flow_sessions_id_seq'::regclass),
  "session_id" text NOT NULL,
  "flow_id" integer NOT NULL,
  "conversation_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "company_id" integer,
  "status" text NOT NULL DEFAULT 'active'::text,
  "current_node_id" text,
  "trigger_node_id" text NOT NULL,
  "execution_path" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "branching_history" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "session_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "node_states" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "waiting_context" jsonb,
  "started_at" timestamp without time zone NOT NULL DEFAULT now(),
  "last_activity_at" timestamp without time zone NOT NULL DEFAULT now(),
  "paused_at" timestamp without time zone,
  "resumed_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "expires_at" timestamp without time zone,
  "total_duration_ms" integer,
  "node_execution_count" integer DEFAULT 0,
  "user_interaction_count" integer DEFAULT 0,
  "error_count" integer DEFAULT 0,
  "last_error_message" text,
  "checkpoint_data" jsonb,
  "debug_info" jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flow_session_variables
CREATE TABLE IF NOT EXISTS "flow_session_variables" (
  "id" integer NOT NULL DEFAULT nextval('flow_session_variables_id_seq'::regclass),
  "session_id" text NOT NULL,
  "variable_key" text NOT NULL,
  "variable_value" jsonb NOT NULL,
  "variable_type" text NOT NULL DEFAULT 'string'::text,
  "scope" text NOT NULL DEFAULT 'session'::text,
  "node_id" text,
  "is_encrypted" boolean DEFAULT false,
  "expires_at" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: flow_step_executions
CREATE TABLE IF NOT EXISTS "flow_step_executions" (
  "id" integer NOT NULL DEFAULT nextval('flow_step_executions_id_seq'::regclass),
  "flow_execution_id" integer NOT NULL,
  "node_id" text NOT NULL,
  "node_type" text NOT NULL,
  "step_order" integer NOT NULL,
  "started_at" timestamp without time zone NOT NULL DEFAULT now(),
  "completed_at" timestamp without time zone,
  "duration_ms" integer,
  "status" text NOT NULL DEFAULT 'running'::text,
  "input_data" jsonb,
  "output_data" jsonb,
  "error_message" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "session_id" text,
  "retry_count" integer DEFAULT 0,
  "max_retries" integer DEFAULT 0,
  PRIMARY KEY ("id")
);

-- Table: flow_session_cursors
CREATE TABLE IF NOT EXISTS "flow_session_cursors" (
  "id" integer NOT NULL DEFAULT nextval('flow_session_cursors_id_seq'::regclass),
  "session_id" text NOT NULL,
  "current_node_id" text NOT NULL,
  "previous_node_id" text,
  "next_possible_nodes" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "branch_conditions" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "loop_state" jsonb,
  "waiting_for_input" boolean DEFAULT false,
  "input_expected_type" text,
  "input_validation_rules" jsonb,
  "timeout_at" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: follow_up_templates
CREATE TABLE IF NOT EXISTS "follow_up_templates" (
  "id" integer NOT NULL DEFAULT nextval('follow_up_templates_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "message_type" text NOT NULL DEFAULT 'text'::text,
  "content" text NOT NULL,
  "media_url" text,
  "caption" text,
  "default_delay_amount" integer DEFAULT 24,
  "default_delay_unit" text DEFAULT 'hours'::text,
  "variables" jsonb DEFAULT '[]'::jsonb,
  "category" text DEFAULT 'general'::text,
  "is_active" boolean DEFAULT true,
  "usage_count" integer DEFAULT 0,
  "created_by" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: team_invitations
CREATE TABLE IF NOT EXISTS "team_invitations" (
  "id" integer NOT NULL DEFAULT nextval('team_invitations_id_seq'::regclass),
  "email" text NOT NULL,
  "invited_by_user_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "role" text NOT NULL DEFAULT 'agent'::text,
  "token" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "expires_at" timestamp without time zone NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deals
CREATE TABLE IF NOT EXISTS "deals" (
  "id" integer NOT NULL DEFAULT nextval('deals_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "title" text NOT NULL,
  "stage_id" integer,
  "stage" text NOT NULL DEFAULT 'lead'::text,
  "value" integer,
  "priority" text DEFAULT 'medium'::text,
  "due_date" timestamp without time zone,
  "assigned_to_user_id" integer,
  "description" text,
  "tags" text[],
  "status" text DEFAULT 'active'::text,
  "last_activity_at" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deal_activities
CREATE TABLE IF NOT EXISTS "deal_activities" (
  "id" integer NOT NULL DEFAULT nextval('deal_activities_id_seq'::regclass),
  "deal_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "type" text NOT NULL,
  "content" text NOT NULL,
  "metadata" jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: google_calendar_tokens
CREATE TABLE IF NOT EXISTS "google_calendar_tokens" (
  "id" integer NOT NULL DEFAULT nextval('google_calendar_tokens_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "access_token" text NOT NULL,
  "refresh_token" text,
  "id_token" text,
  "token_type" text,
  "expiry_date" timestamp without time zone,
  "scope" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: app_settings
CREATE TABLE IF NOT EXISTS "app_settings" (
  "id" integer NOT NULL DEFAULT nextval('app_settings_id_seq'::regclass),
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: company_settings
CREATE TABLE IF NOT EXISTS "company_settings" (
  "id" integer NOT NULL DEFAULT nextval('company_settings_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: pipeline_stages
CREATE TABLE IF NOT EXISTS "pipeline_stages" (
  "id" integer NOT NULL DEFAULT nextval('pipeline_stages_id_seq'::regclass),
  "company_id" integer,
  "name" text NOT NULL,
  "color" text NOT NULL,
  "order_num" integer NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "pipeline_id" integer,
  PRIMARY KEY ("id")
);

-- Table: payment_transactions
CREATE TABLE IF NOT EXISTS "payment_transactions" (
  "id" integer NOT NULL DEFAULT nextval('payment_transactions_id_seq'::regclass),
  "company_id" integer,
  "plan_id" integer,
  "amount" numeric NOT NULL,
  "currency" text NOT NULL DEFAULT 'USD'::text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "payment_method" text NOT NULL,
  "payment_intent_id" text,
  "external_transaction_id" text,
  "receipt_url" text,
  "metadata" jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "original_amount" numeric,
  "discount_amount" numeric DEFAULT 0,
  "coupon_code_id" integer,
  "affiliate_credit_applied" numeric DEFAULT 0,
  "discount_details" jsonb DEFAULT '{}'::jsonb,
  "is_recurring" boolean DEFAULT false,
  "subscription_period_start" timestamp without time zone,
  "subscription_period_end" timestamp without time zone,
  "proration_amount" numeric DEFAULT 0,
  "dunning_attempt" integer DEFAULT 0,
  PRIMARY KEY ("id")
);

-- Table: password_reset_tokens
CREATE TABLE IF NOT EXISTS "password_reset_tokens" (
  "id" integer NOT NULL DEFAULT nextval('password_reset_tokens_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "token" VARCHAR(255) NOT NULL,
  "expires_at" timestamp without time zone NOT NULL,
  "used_at" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "ip_address" inet,
  "user_agent" text,
  PRIMARY KEY ("id")
);

-- Table: translation_namespaces
CREATE TABLE IF NOT EXISTS "translation_namespaces" (
  "id" integer NOT NULL DEFAULT nextval('translation_namespaces_id_seq'::regclass),
  "name" text NOT NULL,
  "description" text,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: translation_keys
CREATE TABLE IF NOT EXISTS "translation_keys" (
  "id" integer NOT NULL DEFAULT nextval('translation_keys_id_seq'::regclass),
  "namespace_id" integer NOT NULL,
  "key" text NOT NULL,
  "description" text,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: translations
CREATE TABLE IF NOT EXISTS "translations" (
  "id" integer NOT NULL DEFAULT nextval('translations_id_seq'::regclass),
  "key_id" integer NOT NULL,
  "language_id" integer NOT NULL,
  "value" text NOT NULL,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: languages
CREATE TABLE IF NOT EXISTS "languages" (
  "id" integer NOT NULL DEFAULT nextval('languages_id_seq'::regclass),
  "code" text NOT NULL,
  "name" text NOT NULL,
  "native_name" text NOT NULL,
  "flag_icon" text,
  "is_active" boolean DEFAULT true,
  "is_default" boolean DEFAULT false,
  "direction" text DEFAULT 'ltr'::text,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: session
CREATE TABLE IF NOT EXISTS "session" (
  "sid" VARCHAR(255) NOT NULL,
  "sess" json NOT NULL,
  "expire" timestamp without time zone NOT NULL,
  PRIMARY KEY ("sid")
);

-- Table: system_updates
CREATE TABLE IF NOT EXISTS "system_updates" (
  "id" integer NOT NULL DEFAULT nextval('system_updates_id_seq'::regclass),
  "version" text NOT NULL,
  "release_notes" text,
  "download_url" text NOT NULL,
  "package_hash" text,
  "package_size" integer,
  "status" update_status NOT NULL DEFAULT 'pending'::update_status,
  "scheduled_at" timestamp without time zone,
  "started_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "error_message" text,
  "rollback_data" jsonb,
  "migration_scripts" jsonb DEFAULT '[]'::jsonb,
  "backup_path" text,
  "progress_percentage" integer DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: contact_segments
CREATE TABLE IF NOT EXISTS "contact_segments" (
  "id" integer NOT NULL DEFAULT nextval('contact_segments_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "criteria" jsonb NOT NULL,
  "contact_count" integer DEFAULT 0,
  "last_updated_at" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: backup_logs
CREATE TABLE IF NOT EXISTS "backup_logs" (
  "id" integer NOT NULL DEFAULT nextval('backup_logs_id_seq'::regclass),
  "log_id" text NOT NULL,
  "schedule_id" text,
  "backup_id" text,
  "status" text NOT NULL,
  "timestamp" timestamp without time zone DEFAULT now(),
  "error_message" text,
  "metadata" jsonb,
  PRIMARY KEY ("id")
);

-- Table: campaign_templates
CREATE TABLE IF NOT EXISTS "campaign_templates" (
  "id" integer NOT NULL DEFAULT nextval('campaign_templates_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "category" text DEFAULT 'general'::text,
  "content" text NOT NULL,
  "content_type" text DEFAULT 'text'::text,
  "media_urls" jsonb DEFAULT '[]'::jsonb,
  "media_metadata" jsonb DEFAULT '{}'::jsonb,
  "variables" jsonb DEFAULT '[]'::jsonb,
  "channel_type" text NOT NULL DEFAULT 'whatsapp'::text,
  "is_active" boolean DEFAULT true,
  "usage_count" integer DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "whatsapp_channel_type" text DEFAULT 'unofficial'::text,
  "whatsapp_template_category" text,
  "whatsapp_template_status" text DEFAULT 'pending'::text,
  "whatsapp_template_id" text,
  "whatsapp_template_name" text,
  "whatsapp_template_language" text DEFAULT 'en'::text,
  "connection_id" integer,
  "media_handle" text,
  PRIMARY KEY ("id")
);

-- Table: campaigns
CREATE TABLE IF NOT EXISTS "campaigns" (
  "id" integer NOT NULL DEFAULT nextval('campaigns_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_id" integer NOT NULL,
  "template_id" integer,
  "segment_id" integer,
  "name" text NOT NULL,
  "description" text,
  "channel_type" text NOT NULL DEFAULT 'whatsapp'::text,
  "channel_id" integer,
  "channel_ids" jsonb DEFAULT '[]'::jsonb,
  "content" text NOT NULL,
  "media_urls" jsonb DEFAULT '[]'::jsonb,
  "variables" jsonb DEFAULT '{}'::jsonb,
  "campaign_type" text NOT NULL DEFAULT 'immediate'::text,
  "scheduled_at" timestamp without time zone,
  "timezone" text DEFAULT 'UTC'::text,
  "drip_settings" jsonb,
  "status" text NOT NULL DEFAULT 'draft'::text,
  "started_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "paused_at" timestamp without time zone,
  "total_recipients" integer DEFAULT 0,
  "processed_recipients" integer DEFAULT 0,
  "successful_sends" integer DEFAULT 0,
  "failed_sends" integer DEFAULT 0,
  "rate_limit_settings" jsonb DEFAULT '{"messages_per_day": 1000, "messages_per_hour": 200, "random_delay_range": [3, 10], "messages_per_minute": 10, "humanization_enabled": true, "delay_between_messages": 6}'::jsonb,
  "compliance_settings" jsonb DEFAULT '{"require_opt_out": true, "spam_check_enabled": true, "content_filter_enabled": true}'::jsonb,
  "anti_ban_settings" jsonb DEFAULT '{"mode": "moderate", "enabled": true, "maxDelay": 15, "minDelay": 3, "cooldownPeriod": 30, "randomizeDelay": true, "accountRotation": true, "respectWeekends": false, "messageVariation": false, "businessHoursOnly": false}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "whatsapp_channel_type" text NOT NULL DEFAULT 'unofficial'::text,
  PRIMARY KEY ("id")
);

-- Table: campaign_recipients
CREATE TABLE IF NOT EXISTS "campaign_recipients" (
  "id" integer NOT NULL DEFAULT nextval('campaign_recipients_id_seq'::regclass),
  "campaign_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "personalized_content" text,
  "variables" jsonb DEFAULT '{}'::jsonb,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "scheduled_at" timestamp without time zone,
  "sent_at" timestamp without time zone,
  "delivered_at" timestamp without time zone,
  "read_at" timestamp without time zone,
  "failed_at" timestamp without time zone,
  "error_message" text,
  "retry_count" integer DEFAULT 0,
  "max_retries" integer DEFAULT 3,
  "external_message_id" text,
  "conversation_id" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: campaign_messages
CREATE TABLE IF NOT EXISTS "campaign_messages" (
  "id" integer NOT NULL DEFAULT nextval('campaign_messages_id_seq'::regclass),
  "campaign_id" integer NOT NULL,
  "recipient_id" integer NOT NULL,
  "message_id" integer,
  "content" text NOT NULL,
  "media_urls" jsonb DEFAULT '[]'::jsonb,
  "message_type" text DEFAULT 'text'::text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "sent_at" timestamp without time zone,
  "delivered_at" timestamp without time zone,
  "read_at" timestamp without time zone,
  "failed_at" timestamp without time zone,
  "whatsapp_message_id" text,
  "whatsapp_status" text,
  "error_code" text,
  "error_message" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: campaign_analytics
CREATE TABLE IF NOT EXISTS "campaign_analytics" (
  "id" integer NOT NULL DEFAULT nextval('campaign_analytics_id_seq'::regclass),
  "campaign_id" integer NOT NULL,
  "recorded_at" timestamp without time zone NOT NULL DEFAULT now(),
  "total_recipients" integer DEFAULT 0,
  "messages_sent" integer DEFAULT 0,
  "messages_delivered" integer DEFAULT 0,
  "messages_read" integer DEFAULT 0,
  "messages_failed" integer DEFAULT 0,
  "delivery_rate" numeric DEFAULT 0.00,
  "read_rate" numeric DEFAULT 0.00,
  "failure_rate" numeric DEFAULT 0.00,
  "avg_delivery_time" integer,
  "avg_read_time" integer,
  "estimated_cost" numeric DEFAULT 0.0000,
  "metrics_data" jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY ("id")
);

-- Table: whatsapp_accounts
CREATE TABLE IF NOT EXISTS "whatsapp_accounts" (
  "id" integer NOT NULL DEFAULT nextval('whatsapp_accounts_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "channel_id" integer,
  "account_name" text NOT NULL,
  "phone_number" text NOT NULL,
  "account_type" text NOT NULL DEFAULT 'unofficial'::text,
  "session_data" jsonb,
  "qr_code" text,
  "connection_status" text DEFAULT 'disconnected'::text,
  "last_activity_at" timestamp without time zone,
  "message_count_today" integer DEFAULT 0,
  "message_count_hour" integer DEFAULT 0,
  "warning_count" integer DEFAULT 0,
  "restriction_count" integer DEFAULT 0,
  "rate_limits" jsonb DEFAULT '{"cooldown_period": 300, "humanization_enabled": true, "max_messages_per_day": 1000, "max_messages_per_hour": 200, "max_messages_per_minute": 10}'::jsonb,
  "health_score" integer DEFAULT 100,
  "last_health_check" timestamp without time zone,
  "is_active" boolean DEFAULT true,
  "rotation_group" text,
  "priority" integer DEFAULT 1,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: whatsapp_account_logs
CREATE TABLE IF NOT EXISTS "whatsapp_account_logs" (
  "id" integer NOT NULL DEFAULT nextval('whatsapp_account_logs_id_seq'::regclass),
  "account_id" integer NOT NULL,
  "event_type" text NOT NULL,
  "event_data" jsonb,
  "message" text,
  "severity" text DEFAULT 'info'::text,
  "messages_sent_today" integer DEFAULT 0,
  "health_score" integer DEFAULT 100,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: campaign_queue
CREATE TABLE IF NOT EXISTS "campaign_queue" (
  "id" integer NOT NULL DEFAULT nextval('campaign_queue_id_seq'::regclass),
  "campaign_id" integer NOT NULL,
  "recipient_id" integer NOT NULL,
  "account_id" integer,
  "priority" integer DEFAULT 1,
  "scheduled_for" timestamp without time zone NOT NULL,
  "attempts" integer DEFAULT 0,
  "max_attempts" integer DEFAULT 3,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "started_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "error_message" text,
  "last_error_at" timestamp without time zone,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: follow_up_execution_log
CREATE TABLE IF NOT EXISTS "follow_up_execution_log" (
  "id" integer NOT NULL DEFAULT nextval('follow_up_execution_log_id_seq'::regclass),
  "schedule_id" text NOT NULL,
  "execution_attempt" integer NOT NULL DEFAULT 1,
  "status" text NOT NULL,
  "message_id" text,
  "error_message" text,
  "execution_duration_ms" integer,
  "executed_at" timestamp without time zone NOT NULL DEFAULT now(),
  "response_received" boolean DEFAULT false,
  "response_at" timestamp without time zone,
  "response_content" text,
  PRIMARY KEY ("id")
);

-- Table: migration_log
CREATE TABLE IF NOT EXISTS "migration_log" (
  "id" integer NOT NULL DEFAULT nextval('migration_log_id_seq'::regclass),
  "migration_name" text NOT NULL,
  "executed_at" timestamp without time zone DEFAULT now(),
  "description" text,
  PRIMARY KEY ("id")
);

-- Table: dialog_360_clients
CREATE TABLE IF NOT EXISTS "dialog_360_clients" (
  "id" integer NOT NULL DEFAULT nextval('dialog_360_clients_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "client_id" text NOT NULL,
  "client_name" text NOT NULL,
  "status" text NOT NULL DEFAULT 'active'::text,
  "onboarded_at" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: meta_whatsapp_clients
CREATE TABLE IF NOT EXISTS "meta_whatsapp_clients" (
  "id" integer NOT NULL DEFAULT nextval('meta_whatsapp_clients_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "business_account_id" text NOT NULL,
  "business_account_name" text,
  "status" text NOT NULL DEFAULT 'active'::text,
  "onboarded_at" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: dialog_360_channels
CREATE TABLE IF NOT EXISTS "dialog_360_channels" (
  "id" integer NOT NULL DEFAULT nextval('dialog_360_channels_id_seq'::regclass),
  "client_id" integer NOT NULL,
  "channel_id" text NOT NULL,
  "phone_number" text NOT NULL,
  "display_name" text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "api_key" text,
  "webhook_url" text,
  "quality_rating" text,
  "messaging_limit" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: partner_configurations
CREATE TABLE IF NOT EXISTS "partner_configurations" (
  "id" integer NOT NULL DEFAULT nextval('partner_configurations_id_seq'::regclass),
  "provider" text NOT NULL,
  "partner_api_key" text NOT NULL,
  "partner_secret" text,
  "partner_id" text NOT NULL,
  "webhook_verify_token" text,
  "access_token" text,
  "partner_webhook_url" text NOT NULL,
  "redirect_url" text NOT NULL,
  "public_profile" jsonb DEFAULT '{}'::jsonb,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "config_id" text,
  PRIMARY KEY ("id")
);

-- Table: meta_whatsapp_phone_numbers
CREATE TABLE IF NOT EXISTS "meta_whatsapp_phone_numbers" (
  "id" integer NOT NULL DEFAULT nextval('meta_whatsapp_phone_numbers_id_seq'::regclass),
  "client_id" integer NOT NULL,
  "phone_number_id" text NOT NULL,
  "phone_number" text NOT NULL,
  "display_name" text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "quality_rating" text,
  "messaging_limit" integer,
  "access_token" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: api_keys
CREATE TABLE IF NOT EXISTS "api_keys" (
  "id" integer NOT NULL DEFAULT nextval('api_keys_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "name" text NOT NULL,
  "key_hash" text NOT NULL,
  "key_prefix" text NOT NULL,
  "permissions" jsonb DEFAULT '["messages:send", "channels:read"]'::jsonb,
  "is_active" boolean NOT NULL DEFAULT true,
  "last_used_at" timestamp without time zone,
  "expires_at" timestamp without time zone,
  "rate_limit_per_minute" integer DEFAULT 60,
  "rate_limit_per_hour" integer DEFAULT 1000,
  "rate_limit_per_day" integer DEFAULT 10000,
  "allowed_ips" jsonb DEFAULT '[]'::jsonb,
  "webhook_url" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: api_usage
CREATE TABLE IF NOT EXISTS "api_usage" (
  "id" integer NOT NULL DEFAULT nextval('api_usage_id_seq'::regclass),
  "api_key_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "endpoint" text NOT NULL,
  "method" text NOT NULL,
  "status_code" integer NOT NULL,
  "request_size" integer,
  "response_size" integer,
  "duration" integer,
  "ip_address" text,
  "user_agent" text,
  "request_id" text,
  "error_message" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: api_rate_limits
CREATE TABLE IF NOT EXISTS "api_rate_limits" (
  "id" integer NOT NULL DEFAULT nextval('api_rate_limits_id_seq'::regclass),
  "api_key_id" integer NOT NULL,
  "window_type" text NOT NULL,
  "window_start" timestamp without time zone NOT NULL,
  "request_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: email_attachments
CREATE TABLE IF NOT EXISTS "email_attachments" (
  "id" integer NOT NULL DEFAULT nextval('email_attachments_id_seq'::regclass),
  "message_id" integer NOT NULL,
  "filename" text NOT NULL,
  "content_type" text NOT NULL,
  "size" integer NOT NULL,
  "content_id" text,
  "is_inline" boolean DEFAULT false,
  "file_path" text NOT NULL,
  "download_url" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: email_configs
CREATE TABLE IF NOT EXISTS "email_configs" (
  "id" integer NOT NULL DEFAULT nextval('email_configs_id_seq'::regclass),
  "channel_connection_id" integer NOT NULL,
  "imap_host" text NOT NULL,
  "imap_port" integer NOT NULL DEFAULT 993,
  "imap_secure" boolean DEFAULT true,
  "imap_username" text NOT NULL,
  "imap_password" text,
  "smtp_host" text NOT NULL,
  "smtp_port" integer NOT NULL DEFAULT 465,
  "smtp_secure" boolean DEFAULT false,
  "smtp_username" text NOT NULL,
  "smtp_password" text,
  "oauth_provider" text,
  "oauth_client_id" text,
  "oauth_client_secret" text,
  "oauth_refresh_token" text,
  "oauth_access_token" text,
  "oauth_token_expiry" timestamp without time zone,
  "email_address" text NOT NULL,
  "display_name" text,
  "signature" text,
  "sync_folder" text DEFAULT 'INBOX'::text,
  "sync_frequency" integer DEFAULT 60,
  "max_sync_messages" integer DEFAULT 100,
  "status" text NOT NULL DEFAULT 'active'::text,
  "last_sync_at" timestamp without time zone,
  "last_error" text,
  "connection_data" jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: user_social_accounts
CREATE TABLE IF NOT EXISTS "user_social_accounts" (
  "id" integer NOT NULL DEFAULT nextval('user_social_accounts_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "provider" text NOT NULL,
  "provider_user_id" text NOT NULL,
  "provider_email" text,
  "provider_name" text,
  "provider_avatar_url" text,
  "access_token" text,
  "refresh_token" text,
  "token_expires_at" timestamp without time zone,
  "provider_data" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliates
CREATE TABLE IF NOT EXISTS "affiliates" (
  "id" integer NOT NULL DEFAULT nextval('affiliates_id_seq'::regclass),
  "company_id" integer,
  "user_id" integer,
  "affiliate_code" text NOT NULL,
  "name" text NOT NULL,
  "email" text NOT NULL,
  "phone" text,
  "website" text,
  "status" affiliate_status NOT NULL DEFAULT 'pending'::affiliate_status,
  "approved_by" integer,
  "approved_at" timestamp without time zone,
  "rejection_reason" text,
  "default_commission_rate" numeric DEFAULT 0.00,
  "commission_type" commission_type DEFAULT 'percentage'::commission_type,
  "business_name" text,
  "tax_id" text,
  "address" jsonb,
  "payment_details" jsonb,
  "total_referrals" integer DEFAULT 0,
  "successful_referrals" integer DEFAULT 0,
  "total_earnings" numeric DEFAULT 0.00,
  "pending_earnings" numeric DEFAULT 0.00,
  "paid_earnings" numeric DEFAULT 0.00,
  "notes" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: messages
CREATE TABLE IF NOT EXISTS "messages" (
  "id" integer NOT NULL DEFAULT nextval('messages_id_seq'::regclass),
  "conversation_id" integer NOT NULL,
  "external_id" text,
  "direction" text NOT NULL,
  "type" text DEFAULT 'text'::text,
  "content" text NOT NULL,
  "metadata" jsonb,
  "sender_id" integer,
  "sender_type" text,
  "status" text DEFAULT 'sent'::text,
  "sent_at" timestamp without time zone,
  "read_at" timestamp without time zone,
  "is_from_bot" boolean DEFAULT false,
  "media_url" text,
  "group_participant_jid" text,
  "group_participant_name" text,
  "created_at" timestamp without time zone DEFAULT now(),
  "email_message_id" text,
  "email_in_reply_to" text,
  "email_references" text,
  "email_subject" text,
  "email_from" text,
  "email_to" text,
  "email_cc" text,
  "email_bcc" text,
  "email_html" text,
  "email_plain_text" text,
  "email_headers" jsonb,
  "is_history_sync" boolean DEFAULT false,
  "history_sync_batch_id" text,
  PRIMARY KEY ("id")
);

-- Table: affiliate_commission_structures
CREATE TABLE IF NOT EXISTS "affiliate_commission_structures" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_commission_structures_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "plan_id" integer,
  "name" text NOT NULL,
  "commission_type" commission_type NOT NULL DEFAULT 'percentage'::commission_type,
  "commission_value" numeric NOT NULL,
  "tier_rules" jsonb,
  "minimum_payout" numeric DEFAULT 0.00,
  "maximum_payout" numeric,
  "recurring_commission" boolean DEFAULT false,
  "recurring_months" integer DEFAULT 0,
  "valid_from" timestamp without time zone DEFAULT now(),
  "valid_until" timestamp without time zone,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_referrals
CREATE TABLE IF NOT EXISTS "affiliate_referrals" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_referrals_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "referral_code" text NOT NULL,
  "referred_company_id" integer,
  "referred_user_id" integer,
  "referred_email" text,
  "status" referral_status NOT NULL DEFAULT 'pending'::referral_status,
  "converted_at" timestamp without time zone,
  "conversion_value" numeric DEFAULT 0.00,
  "commission_structure_id" integer,
  "commission_amount" numeric DEFAULT 0.00,
  "commission_rate" numeric DEFAULT 0.00,
  "source_url" text,
  "utm_source" text,
  "utm_medium" text,
  "utm_campaign" text,
  "utm_content" text,
  "utm_term" text,
  "user_agent" text,
  "ip_address" inet,
  "country_code" text,
  "expires_at" timestamp without time zone,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_payouts
CREATE TABLE IF NOT EXISTS "affiliate_payouts" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_payouts_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "amount" numeric NOT NULL,
  "currency" text NOT NULL DEFAULT 'USD'::text,
  "status" payout_status NOT NULL DEFAULT 'pending'::payout_status,
  "payment_method" text,
  "payment_reference" text,
  "external_transaction_id" text,
  "period_start" timestamp without time zone NOT NULL,
  "period_end" timestamp without time zone NOT NULL,
  "processed_by" integer,
  "processed_at" timestamp without time zone,
  "failure_reason" text,
  "referral_ids" int4[],
  "notes" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_analytics
CREATE TABLE IF NOT EXISTS "affiliate_analytics" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_analytics_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "date" date NOT NULL,
  "period_type" text NOT NULL DEFAULT 'daily'::text,
  "clicks" integer DEFAULT 0,
  "unique_clicks" integer DEFAULT 0,
  "impressions" integer DEFAULT 0,
  "referrals" integer DEFAULT 0,
  "conversions" integer DEFAULT 0,
  "conversion_rate" numeric DEFAULT 0.00,
  "revenue" numeric DEFAULT 0.00,
  "commission_earned" numeric DEFAULT 0.00,
  "average_order_value" numeric DEFAULT 0.00,
  "top_countries" jsonb DEFAULT '[]'::jsonb,
  "top_sources" jsonb DEFAULT '[]'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_clicks
CREATE TABLE IF NOT EXISTS "affiliate_clicks" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_clicks_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "referral_id" integer,
  "clicked_url" text NOT NULL,
  "landing_page" text,
  "session_id" text,
  "user_agent" text,
  "ip_address" inet,
  "country_code" text,
  "city" text,
  "utm_source" text,
  "utm_medium" text,
  "utm_campaign" text,
  "utm_content" text,
  "utm_term" text,
  "referrer_url" text,
  "referrer_domain" text,
  "device_type" text,
  "browser" text,
  "os" text,
  "converted" boolean DEFAULT false,
  "converted_at" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_relationships
CREATE TABLE IF NOT EXISTS "affiliate_relationships" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_relationships_id_seq'::regclass),
  "company_id" integer,
  "parent_affiliate_id" integer,
  "child_affiliate_id" integer,
  "level" integer NOT NULL DEFAULT 1,
  "commission_percentage" numeric DEFAULT 0.00,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_applications
CREATE TABLE IF NOT EXISTS "affiliate_applications" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_applications_id_seq'::regclass),
  "first_name" text NOT NULL,
  "last_name" text NOT NULL,
  "email" text NOT NULL,
  "phone" text,
  "company" text,
  "website" text,
  "country" text NOT NULL,
  "marketing_channels" text[] NOT NULL,
  "expected_monthly_referrals" text NOT NULL,
  "experience" text NOT NULL,
  "motivation" text NOT NULL,
  "status" affiliate_application_status NOT NULL DEFAULT 'pending'::affiliate_application_status,
  "agree_to_terms" boolean NOT NULL DEFAULT false,
  "reviewed_by" integer,
  "reviewed_at" timestamp without time zone,
  "review_notes" text,
  "rejection_reason" text,
  "submitted_at" timestamp without time zone NOT NULL DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: coupon_codes
CREATE TABLE IF NOT EXISTS "coupon_codes" (
  "id" integer NOT NULL DEFAULT nextval('coupon_codes_id_seq'::regclass),
  "company_id" integer,
  "code" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "discount_type" text NOT NULL,
  "discount_value" numeric NOT NULL,
  "usage_limit" integer,
  "usage_limit_per_user" integer DEFAULT 1,
  "current_usage_count" integer DEFAULT 0,
  "start_date" timestamp without time zone NOT NULL DEFAULT now(),
  "end_date" timestamp without time zone,
  "applicable_plan_ids" int4[],
  "minimum_plan_value" numeric,
  "is_active" boolean DEFAULT true,
  "created_by" integer,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: coupon_usage
CREATE TABLE IF NOT EXISTS "coupon_usage" (
  "id" integer NOT NULL DEFAULT nextval('coupon_usage_id_seq'::regclass),
  "coupon_id" integer,
  "company_id" integer,
  "user_id" integer,
  "plan_id" integer,
  "original_amount" numeric NOT NULL,
  "discount_amount" numeric NOT NULL,
  "final_amount" numeric NOT NULL,
  "payment_transaction_id" integer,
  "usage_context" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_earnings_balance
CREATE TABLE IF NOT EXISTS "affiliate_earnings_balance" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_earnings_balance_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "total_earned" numeric DEFAULT 0.00,
  "available_balance" numeric DEFAULT 0.00,
  "applied_to_plans" numeric DEFAULT 0.00,
  "pending_payout" numeric DEFAULT 0.00,
  "paid_out" numeric DEFAULT 0.00,
  "last_updated" timestamp without time zone NOT NULL DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: affiliate_earnings_transactions
CREATE TABLE IF NOT EXISTS "affiliate_earnings_transactions" (
  "id" integer NOT NULL DEFAULT nextval('affiliate_earnings_transactions_id_seq'::regclass),
  "company_id" integer,
  "affiliate_id" integer,
  "transaction_type" text NOT NULL,
  "amount" numeric NOT NULL,
  "balance_after" numeric NOT NULL,
  "referral_id" integer,
  "payment_transaction_id" integer,
  "payout_id" integer,
  "description" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: company_ai_preferences
CREATE TABLE IF NOT EXISTS "company_ai_preferences" (
  "id" integer NOT NULL DEFAULT nextval('company_ai_preferences_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "default_provider" VARCHAR(50) DEFAULT 'gemini'::character varying,
  "credential_preference" VARCHAR(20) DEFAULT 'system'::character varying,
  "fallback_enabled" boolean DEFAULT true,
  "usage_alerts_enabled" boolean DEFAULT true,
  "usage_alert_threshold" integer DEFAULT 80,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: ai_credential_usage
CREATE TABLE IF NOT EXISTS "ai_credential_usage" (
  "id" integer NOT NULL DEFAULT nextval('ai_credential_usage_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "credential_type" VARCHAR(20) NOT NULL,
  "credential_id" integer,
  "provider" VARCHAR(50) NOT NULL,
  "model" VARCHAR(100),
  "tokens_input" integer DEFAULT 0,
  "tokens_output" integer DEFAULT 0,
  "tokens_total" integer DEFAULT 0,
  "cost_estimated" numeric DEFAULT 0.00,
  "request_count" integer DEFAULT 1,
  "conversation_id" integer,
  "flow_id" integer,
  "node_id" VARCHAR(100),
  "usage_date" date NOT NULL DEFAULT CURRENT_DATE,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: plan_ai_provider_configs
CREATE TABLE IF NOT EXISTS "plan_ai_provider_configs" (
  "id" integer NOT NULL DEFAULT nextval('plan_ai_provider_configs_id_seq'::regclass),
  "plan_id" integer NOT NULL,
  "provider" VARCHAR(50) NOT NULL,
  "tokens_monthly_limit" integer,
  "tokens_daily_limit" integer,
  "custom_pricing_enabled" boolean DEFAULT false,
  "input_token_rate" numeric DEFAULT NULL::numeric,
  "output_token_rate" numeric DEFAULT NULL::numeric,
  "enabled" boolean DEFAULT true,
  "priority" integer DEFAULT 0,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: plan_ai_usage_tracking
CREATE TABLE IF NOT EXISTS "plan_ai_usage_tracking" (
  "id" integer NOT NULL DEFAULT nextval('plan_ai_usage_tracking_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "plan_id" integer NOT NULL,
  "provider" VARCHAR(50) NOT NULL,
  "tokens_used_monthly" integer DEFAULT 0,
  "tokens_used_daily" integer DEFAULT 0,
  "requests_monthly" integer DEFAULT 0,
  "requests_daily" integer DEFAULT 0,
  "cost_monthly" numeric DEFAULT 0.000000,
  "cost_daily" numeric DEFAULT 0.000000,
  "overage_tokens_monthly" integer DEFAULT 0,
  "overage_cost_monthly" numeric DEFAULT 0.000000,
  "usage_month" integer NOT NULL,
  "usage_year" integer NOT NULL,
  "usage_date" date NOT NULL,
  "monthly_limit_reached" boolean DEFAULT false,
  "daily_limit_reached" boolean DEFAULT false,
  "monthly_warning_sent" boolean DEFAULT false,
  "daily_warning_sent" boolean DEFAULT false,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: plan_ai_billing_events
CREATE TABLE IF NOT EXISTS "plan_ai_billing_events" (
  "id" integer NOT NULL DEFAULT nextval('plan_ai_billing_events_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "plan_id" integer NOT NULL,
  "provider" VARCHAR(50) NOT NULL,
  "event_type" VARCHAR(50) NOT NULL,
  "event_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "tokens_consumed" integer DEFAULT 0,
  "cost_amount" numeric DEFAULT 0.000000,
  "billing_period_start" date,
  "billing_period_end" date,
  "processed" boolean DEFAULT false,
  "processed_at" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "metadata" jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY ("id")
);

-- Table: system_ai_credentials
CREATE TABLE IF NOT EXISTS "system_ai_credentials" (
  "id" integer NOT NULL DEFAULT nextval('system_ai_credentials_id_seq'::regclass),
  "provider" VARCHAR(50) NOT NULL,
  "api_key_encrypted" text NOT NULL,
  "display_name" VARCHAR(100),
  "description" text,
  "is_active" boolean NOT NULL DEFAULT true,
  "is_default" boolean NOT NULL DEFAULT false,
  "usage_limit_monthly" integer,
  "usage_count_current" integer DEFAULT 0,
  "last_validated_at" timestamp without time zone,
  "validation_status" VARCHAR(20) DEFAULT 'pending'::character varying,
  "validation_error" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: company_ai_credentials
CREATE TABLE IF NOT EXISTS "company_ai_credentials" (
  "id" integer NOT NULL DEFAULT nextval('company_ai_credentials_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "provider" VARCHAR(50) NOT NULL,
  "api_key_encrypted" text NOT NULL,
  "display_name" VARCHAR(100),
  "description" text,
  "is_active" boolean NOT NULL DEFAULT true,
  "usage_limit_monthly" integer,
  "usage_count_current" integer DEFAULT 0,
  "last_validated_at" timestamp without time zone,
  "validation_status" VARCHAR(20) DEFAULT 'pending'::character varying,
  "validation_error" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: subscription_events
CREATE TABLE IF NOT EXISTS "subscription_events" (
  "id" integer NOT NULL DEFAULT nextval('subscription_events_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "event_type" text NOT NULL,
  "event_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "previous_status" text,
  "new_status" text,
  "triggered_by" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: subscription_usage_tracking
CREATE TABLE IF NOT EXISTS "subscription_usage_tracking" (
  "id" integer NOT NULL DEFAULT nextval('subscription_usage_tracking_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "metric_name" text NOT NULL,
  "current_usage" integer NOT NULL DEFAULT 0,
  "limit_value" integer NOT NULL,
  "soft_limit_reached" boolean DEFAULT false,
  "hard_limit_reached" boolean DEFAULT false,
  "last_warning_sent" timestamp without time zone,
  "reset_period" text DEFAULT 'monthly'::text,
  "last_reset" timestamp without time zone DEFAULT now(),
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: dunning_management
CREATE TABLE IF NOT EXISTS "dunning_management" (
  "id" integer NOT NULL DEFAULT nextval('dunning_management_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "payment_transaction_id" integer,
  "attempt_number" integer NOT NULL DEFAULT 1,
  "attempt_date" timestamp without time zone NOT NULL DEFAULT now(),
  "attempt_type" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "response_data" jsonb,
  "next_attempt_date" timestamp without time zone,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: subscription_plan_changes
CREATE TABLE IF NOT EXISTS "subscription_plan_changes" (
  "id" integer NOT NULL DEFAULT nextval('subscription_plan_changes_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "from_plan_id" integer,
  "to_plan_id" integer NOT NULL,
  "change_type" text NOT NULL,
  "effective_date" timestamp without time zone NOT NULL DEFAULT now(),
  "proration_amount" numeric DEFAULT 0,
  "proration_days" integer DEFAULT 0,
  "billing_cycle_reset" boolean DEFAULT false,
  "change_reason" text,
  "processed" boolean DEFAULT false,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: subscription_notifications
CREATE TABLE IF NOT EXISTS "subscription_notifications" (
  "id" integer NOT NULL DEFAULT nextval('subscription_notifications_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "notification_type" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "scheduled_for" timestamp without time zone NOT NULL,
  "sent_at" timestamp without time zone,
  "notification_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "delivery_method" text DEFAULT 'email'::text,
  "retry_count" integer DEFAULT 0,
  "max_retries" integer DEFAULT 3,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: follow_up_schedules
CREATE TABLE IF NOT EXISTS "follow_up_schedules" (
  "id" integer NOT NULL DEFAULT nextval('follow_up_schedules_id_seq'::regclass),
  "schedule_id" text NOT NULL,
  "session_id" text,
  "flow_id" integer NOT NULL,
  "conversation_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "company_id" integer,
  "node_id" text NOT NULL,
  "message_type" text NOT NULL DEFAULT 'text'::text,
  "message_content" text,
  "media_url" text,
  "caption" text,
  "template_id" integer,
  "trigger_event" text NOT NULL DEFAULT 'conversation_start'::text,
  "trigger_node_id" text,
  "delay_amount" integer,
  "delay_unit" text,
  "scheduled_for" timestamp without time zone,
  "specific_datetime" timestamp without time zone,
  "status" text NOT NULL DEFAULT 'scheduled'::text,
  "sent_at" timestamp without time zone,
  "failed_reason" text,
  "retry_count" integer DEFAULT 0,
  "max_retries" integer DEFAULT 3,
  "channel_type" text NOT NULL,
  "channel_connection_id" integer,
  "variables" jsonb DEFAULT '{}'::jsonb,
  "execution_context" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "expires_at" timestamp without time zone,
  "timezone" text DEFAULT 'UTC'::text,
  PRIMARY KEY ("id")
);

-- Table: website_templates
CREATE TABLE IF NOT EXISTS "website_templates" (
  "id" integer NOT NULL DEFAULT nextval('website_templates_id_seq'::regclass),
  "name" text NOT NULL,
  "description" text,
  "category" text DEFAULT 'general'::text,
  "preview_image" text,
  "preview_url" text,
  "grapes_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "grapes_html" text,
  "grapes_css" text,
  "grapes_js" text,
  "is_active" boolean DEFAULT true,
  "is_premium" boolean DEFAULT false,
  "tags" text[],
  "usage_count" integer DEFAULT 0,
  "created_by_id" integer NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: websites
CREATE TABLE IF NOT EXISTS "websites" (
  "id" integer NOT NULL DEFAULT nextval('websites_id_seq'::regclass),
  "title" text NOT NULL,
  "slug" text NOT NULL,
  "description" text,
  "meta_title" text,
  "meta_description" text,
  "meta_keywords" text,
  "grapes_data" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "grapes_html" text,
  "grapes_css" text,
  "grapes_js" text,
  "favicon" text,
  "custom_css" text,
  "custom_js" text,
  "custom_head" text,
  "status" text NOT NULL DEFAULT 'draft'::text,
  "published_at" timestamp without time zone,
  "google_analytics_id" text,
  "facebook_pixel_id" text,
  "template_id" integer,
  "theme" text DEFAULT 'default'::text,
  "created_by_id" integer NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: knowledge_base_documents
CREATE TABLE IF NOT EXISTS "knowledge_base_documents" (
  "id" integer NOT NULL DEFAULT nextval('knowledge_base_documents_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "node_id" text,
  "filename" text NOT NULL,
  "original_name" text NOT NULL,
  "mime_type" text NOT NULL,
  "file_size" integer NOT NULL,
  "status" text NOT NULL DEFAULT 'uploading'::text,
  "file_path" text NOT NULL,
  "file_url" text,
  "extracted_text" text,
  "chunk_count" integer DEFAULT 0,
  "embedding_model" text DEFAULT 'text-embedding-3-small'::text,
  "processing_error" text,
  "processing_duration_ms" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: website_assets
CREATE TABLE IF NOT EXISTS "website_assets" (
  "id" integer NOT NULL DEFAULT nextval('website_assets_id_seq'::regclass),
  "website_id" integer NOT NULL,
  "filename" text NOT NULL,
  "original_name" text NOT NULL,
  "mime_type" text NOT NULL,
  "size" integer NOT NULL,
  "path" text NOT NULL,
  "url" text NOT NULL,
  "alt" text,
  "title" text,
  "asset_type" text NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: quick_reply_templates
CREATE TABLE IF NOT EXISTS "quick_reply_templates" (
  "id" integer NOT NULL DEFAULT nextval('quick_reply_templates_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_id" integer NOT NULL,
  "name" text NOT NULL,
  "content" text NOT NULL,
  "category" text DEFAULT 'general'::text,
  "variables" jsonb DEFAULT '[]'::jsonb,
  "is_active" boolean DEFAULT true,
  "usage_count" integer DEFAULT 0,
  "sort_order" integer DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: knowledge_base_chunks
CREATE TABLE IF NOT EXISTS "knowledge_base_chunks" (
  "id" integer NOT NULL DEFAULT nextval('knowledge_base_chunks_id_seq'::regclass),
  "document_id" integer NOT NULL,
  "content" text NOT NULL,
  "chunk_index" integer NOT NULL,
  "token_count" integer,
  "start_position" integer,
  "end_position" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: knowledge_base_configs
CREATE TABLE IF NOT EXISTS "knowledge_base_configs" (
  "id" integer NOT NULL DEFAULT nextval('knowledge_base_configs_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "node_id" text NOT NULL,
  "flow_id" integer,
  "enabled" boolean DEFAULT true,
  "max_retrieved_chunks" integer DEFAULT 3,
  "similarity_threshold" real DEFAULT 0.7,
  "embedding_model" text DEFAULT 'text-embedding-3-small'::text,
  "context_position" text DEFAULT 'before_system'::text,
  "context_template" text DEFAULT 'Based on the following knowledge base information:

{context}

Please answer the user''s question using this information when relevant.'::text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: knowledge_base_document_nodes
CREATE TABLE IF NOT EXISTS "knowledge_base_document_nodes" (
  "id" integer NOT NULL DEFAULT nextval('knowledge_base_document_nodes_id_seq'::regclass),
  "document_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "node_id" text NOT NULL,
  "flow_id" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: knowledge_base_usage
CREATE TABLE IF NOT EXISTS "knowledge_base_usage" (
  "id" integer NOT NULL DEFAULT nextval('knowledge_base_usage_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "node_id" text NOT NULL,
  "document_id" integer,
  "query_text" text NOT NULL,
  "query_embedding" text,
  "chunks_retrieved" integer DEFAULT 0,
  "chunks_used" integer DEFAULT 0,
  "similarity_scores" jsonb DEFAULT '[]'::jsonb,
  "retrieval_duration_ms" integer,
  "embedding_duration_ms" integer,
  "context_injected" boolean DEFAULT false,
  "context_length" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: contact_documents
CREATE TABLE IF NOT EXISTS "contact_documents" (
  "id" integer NOT NULL DEFAULT nextval('contact_documents_id_seq'::regclass),
  "contact_id" integer NOT NULL,
  "filename" text NOT NULL,
  "original_name" text NOT NULL,
  "mime_type" text NOT NULL,
  "file_size" integer NOT NULL,
  "file_path" text NOT NULL,
  "file_url" text NOT NULL,
  "category" text NOT NULL DEFAULT 'general'::text,
  "description" text,
  "uploaded_by" integer,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: contact_appointments
CREATE TABLE IF NOT EXISTS "contact_appointments" (
  "id" integer NOT NULL DEFAULT nextval('contact_appointments_id_seq'::regclass),
  "contact_id" integer NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "location" text,
  "scheduled_at" timestamp without time zone NOT NULL,
  "duration_minutes" integer DEFAULT 60,
  "type" text NOT NULL DEFAULT 'meeting'::text,
  "status" text NOT NULL DEFAULT 'scheduled'::text,
  "created_by" integer,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: zoho_calendar_tokens
CREATE TABLE IF NOT EXISTS "zoho_calendar_tokens" (
  "id" integer NOT NULL DEFAULT nextval('zoho_calendar_tokens_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "access_token" text NOT NULL,
  "refresh_token" text,
  "token_type" text,
  "expires_in" integer,
  "scope" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: history_sync_batches
CREATE TABLE IF NOT EXISTS "history_sync_batches" (
  "id" integer NOT NULL DEFAULT nextval('history_sync_batches_id_seq'::regclass),
  "connection_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "batch_id" text NOT NULL,
  "sync_type" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "total_chats" integer DEFAULT 0,
  "processed_chats" integer DEFAULT 0,
  "total_messages" integer DEFAULT 0,
  "processed_messages" integer DEFAULT 0,
  "total_contacts" integer DEFAULT 0,
  "processed_contacts" integer DEFAULT 0,
  "error_message" text,
  "started_at" timestamp without time zone DEFAULT now(),
  "completed_at" timestamp without time zone,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: contact_audit_logs
CREATE TABLE IF NOT EXISTS "contact_audit_logs" (
  "id" integer NOT NULL DEFAULT nextval('contact_audit_logs_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "contact_id" integer NOT NULL,
  "user_id" integer,
  "action_type" VARCHAR(50) NOT NULL,
  "action_category" VARCHAR(30) NOT NULL DEFAULT 'contact'::character varying,
  "description" text NOT NULL,
  "old_values" jsonb,
  "new_values" jsonb,
  "metadata" jsonb,
  "ip_address" inet,
  "user_agent" text,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: calendly_calendar_tokens
CREATE TABLE IF NOT EXISTS "calendly_calendar_tokens" (
  "id" integer NOT NULL DEFAULT nextval('calendly_calendar_tokens_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "company_id" integer NOT NULL,
  "access_token" text NOT NULL,
  "refresh_token" text,
  "token_type" text,
  "expires_in" integer,
  "scope" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: inbox_restores
CREATE TABLE IF NOT EXISTS "inbox_restores" (
  "id" integer NOT NULL DEFAULT nextval('inbox_restores_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "backup_id" integer,
  "restored_by_user_id" integer NOT NULL,
  "status" restore_status NOT NULL DEFAULT 'pending'::restore_status,
  "restore_type" text NOT NULL,
  "conflict_resolution" text DEFAULT 'merge'::text,
  "date_range_start" timestamp without time zone,
  "date_range_end" timestamp without time zone,
  "restore_contacts" boolean DEFAULT true,
  "restore_conversations" boolean DEFAULT true,
  "restore_messages" boolean DEFAULT true,
  "total_items_to_restore" integer DEFAULT 0,
  "items_restored" integer DEFAULT 0,
  "items_skipped" integer DEFAULT 0,
  "items_errored" integer DEFAULT 0,
  "error_message" text,
  "started_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: backup_schedules
CREATE TABLE IF NOT EXISTS "backup_schedules" (
  "id" integer NOT NULL DEFAULT nextval('backup_schedules_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_user_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "is_active" boolean DEFAULT true,
  "frequency" text NOT NULL,
  "cron_expression" text,
  "retention_days" integer DEFAULT 30,
  "include_contacts" boolean DEFAULT true,
  "include_conversations" boolean DEFAULT true,
  "include_messages" boolean DEFAULT true,
  "last_run_at" timestamp without time zone,
  "next_run_at" timestamp without time zone,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  "enabled" boolean DEFAULT true,
  PRIMARY KEY ("id")
);

-- Table: inbox_backups
CREATE TABLE IF NOT EXISTS "inbox_backups" (
  "id" integer NOT NULL DEFAULT nextval('inbox_backups_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "created_by_user_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "type" backup_type NOT NULL DEFAULT 'manual'::backup_type,
  "status" backup_status NOT NULL DEFAULT 'pending'::backup_status,
  "file_path" text,
  "file_name" text,
  "file_size" integer,
  "compressed_size" integer,
  "checksum" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "include_contacts" boolean DEFAULT true,
  "include_conversations" boolean DEFAULT true,
  "include_messages" boolean DEFAULT true,
  "date_range_start" timestamp without time zone,
  "date_range_end" timestamp without time zone,
  "total_contacts" integer DEFAULT 0,
  "total_conversations" integer DEFAULT 0,
  "total_messages" integer DEFAULT 0,
  "error_message" text,
  "started_at" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "expires_at" timestamp without time zone,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: backup_audit_logs
CREATE TABLE IF NOT EXISTS "backup_audit_logs" (
  "id" integer NOT NULL DEFAULT nextval('backup_audit_logs_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "action" text NOT NULL,
  "entity_type" text NOT NULL,
  "entity_id" integer,
  "details" jsonb DEFAULT '{}'::jsonb,
  "ip_address" text,
  "user_agent" text,
  "created_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: calls
CREATE TABLE IF NOT EXISTS "calls" (
  "id" integer NOT NULL DEFAULT nextval('calls_id_seq'::regclass),
  "company_id" integer,
  "channel_id" integer,
  "contact_id" integer,
  "conversation_id" integer,
  "direction" text,
  "status" text,
  "from" text,
  "to" text,
  "duration_sec" integer,
  "started_at" timestamp without time zone,
  "ended_at" timestamp without time zone,
  "recording_url" text,
  "recording_sid" text,
  "twilio_call_sid" text,
  "metadata" jsonb,
  "created_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: task_categories
CREATE TABLE IF NOT EXISTS "task_categories" (
  "id" integer NOT NULL DEFAULT nextval('task_categories_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "name" text NOT NULL,
  "color" text,
  "icon" text,
  "created_by" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: scheduled_messages
CREATE TABLE IF NOT EXISTS "scheduled_messages" (
  "id" integer NOT NULL DEFAULT nextval('scheduled_messages_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "conversation_id" integer NOT NULL,
  "channel_id" integer NOT NULL,
  "channel_type" text NOT NULL,
  "content" text NOT NULL,
  "message_type" text NOT NULL DEFAULT 'text'::text,
  "media_url" text,
  "media_type" text,
  "caption" text,
  "scheduled_for" timestamp without time zone NOT NULL,
  "timezone" text DEFAULT 'UTC'::text,
  "status" scheduled_message_status DEFAULT 'pending'::scheduled_message_status,
  "attempts" integer DEFAULT 0,
  "max_attempts" integer DEFAULT 3,
  "last_attempt_at" timestamp without time zone,
  "sent_at" timestamp without time zone,
  "failed_at" timestamp without time zone,
  "error_message" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_by" integer NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "media_file_path" text,
  PRIMARY KEY ("id")
);

-- Table: contact_tasks
CREATE TABLE IF NOT EXISTS "contact_tasks" (
  "id" integer NOT NULL DEFAULT nextval('contact_tasks_id_seq'::regclass),
  "contact_id" integer,
  "company_id" integer NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "priority" text NOT NULL DEFAULT 'medium'::text,
  "status" text NOT NULL DEFAULT 'not_started'::text,
  "due_date" timestamp without time zone,
  "completed_at" timestamp without time zone,
  "assigned_to" text,
  "category" text,
  "tags" text[],
  "created_by" integer,
  "updated_by" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  "background_color" VARCHAR(7) DEFAULT '#ffffff'::character varying,
  "checklist" jsonb DEFAULT '[]'::jsonb,
  PRIMARY KEY ("id")
);

-- Table: whatsapp_proxy_servers
CREATE TABLE IF NOT EXISTS "whatsapp_proxy_servers" (
  "id" integer NOT NULL DEFAULT nextval('whatsapp_proxy_servers_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "name" text NOT NULL,
  "enabled" boolean NOT NULL DEFAULT true,
  "type" text NOT NULL,
  "host" text NOT NULL,
  "port" integer NOT NULL,
  "username" text,
  "password" text,
  "test_status" text DEFAULT 'untested'::text,
  "last_tested" timestamp without time zone,
  "description" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: channel_connections
CREATE TABLE IF NOT EXISTS "channel_connections" (
  "id" integer NOT NULL DEFAULT nextval('channel_connections_id_seq'::regclass),
  "user_id" integer NOT NULL,
  "company_id" integer,
  "channel_type" text NOT NULL,
  "account_id" text NOT NULL,
  "account_name" text NOT NULL,
  "access_token" text,
  "status" text DEFAULT 'active'::text,
  "connection_data" jsonb,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  "history_sync_enabled" boolean DEFAULT false,
  "history_sync_status" text DEFAULT 'pending'::text,
  "history_sync_progress" integer DEFAULT 0,
  "history_sync_total" integer DEFAULT 0,
  "last_history_sync_at" timestamp without time zone,
  "history_sync_error" text,
  "proxy_enabled" boolean DEFAULT false,
  "proxy_type" text,
  "proxy_host" text,
  "proxy_port" integer,
  "proxy_username" text,
  "proxy_password" text,
  "proxy_test_status" text DEFAULT 'untested'::text,
  "proxy_last_tested" timestamp without time zone,
  "proxy_server_id" integer,
  PRIMARY KEY ("id")
);

-- Table: database_backups
CREATE TABLE IF NOT EXISTS "database_backups" (
  "id" text NOT NULL,
  "filename" text NOT NULL,
  "type" database_backup_type NOT NULL DEFAULT 'manual'::database_backup_type,
  "description" text NOT NULL,
  "size" integer NOT NULL DEFAULT 0,
  "status" database_backup_status NOT NULL DEFAULT 'creating'::database_backup_status,
  "storage_locations" jsonb NOT NULL DEFAULT '["local"]'::jsonb,
  "checksum" text NOT NULL,
  "error_message" text,
  "database_size" integer DEFAULT 0,
  "table_count" integer DEFAULT 0,
  "row_count" integer DEFAULT 0,
  "compression_ratio" real,
  "encryption_enabled" boolean DEFAULT false,
  "app_version" text,
  "pg_version" text,
  "instance_id" text,
  "dump_format" database_backup_format DEFAULT 'sql'::database_backup_format,
  "schema_checksum" text,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: database_backup_logs
CREATE TABLE IF NOT EXISTS "database_backup_logs" (
  "id" text NOT NULL,
  "schedule_id" text NOT NULL,
  "backup_id" text,
  "status" text NOT NULL,
  "timestamp" timestamp without time zone NOT NULL DEFAULT now(),
  "error_message" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: company_pages
CREATE TABLE IF NOT EXISTS "company_pages" (
  "id" integer NOT NULL DEFAULT nextval('company_pages_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "title" VARCHAR(255) NOT NULL,
  "slug" VARCHAR(255) NOT NULL,
  "content" text NOT NULL,
  "meta_title" VARCHAR(255),
  "meta_description" text,
  "meta_keywords" text,
  "is_published" boolean DEFAULT true,
  "is_featured" boolean DEFAULT false,
  "template" VARCHAR(100) DEFAULT 'default'::character varying,
  "custom_css" text,
  "custom_js" text,
  "author_id" integer,
  "published_at" timestamp without time zone,
  "created_at" timestamp without time zone DEFAULT now(),
  "updated_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: tags
CREATE TABLE IF NOT EXISTS "tags" (
  "id" integer NOT NULL DEFAULT nextval('tags_id_seq'::regclass),
  "name" VARCHAR(100) NOT NULL,
  "color" VARCHAR(7),
  "company_id" integer,
  "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

-- Table: contact_tags
CREATE TABLE IF NOT EXISTS "contact_tags" (
  "id" integer NOT NULL DEFAULT nextval('contact_tags_id_seq'::regclass),
  "contact_id" integer,
  "tag_id" integer,
  PRIMARY KEY ("id")
);

-- Table: sessions
CREATE TABLE IF NOT EXISTS "sessions" (
  "id" text NOT NULL,
  "user_id" integer,
  "expires_at" timestamp without time zone NOT NULL,
  "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

-- Table: deal_checklists
CREATE TABLE IF NOT EXISTS "deal_checklists" (
  "id" integer NOT NULL DEFAULT nextval('deal_checklists_id_seq'::regclass),
  "deal_id" integer NOT NULL,
  "title" text NOT NULL,
  "order_num" integer NOT NULL DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deal_checklist_items
CREATE TABLE IF NOT EXISTS "deal_checklist_items" (
  "id" integer NOT NULL DEFAULT nextval('deal_checklist_items_id_seq'::regclass),
  "checklist_id" integer NOT NULL,
  "text" text NOT NULL,
  "is_completed" boolean DEFAULT false,
  "order_num" integer NOT NULL DEFAULT 0,
  "completed_at" timestamp without time zone,
  "completed_by" integer,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deal_comments
CREATE TABLE IF NOT EXISTS "deal_comments" (
  "id" integer NOT NULL DEFAULT nextval('deal_comments_id_seq'::regclass),
  "deal_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "comment" text NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deal_attachments
CREATE TABLE IF NOT EXISTS "deal_attachments" (
  "id" integer NOT NULL DEFAULT nextval('deal_attachments_id_seq'::regclass),
  "deal_id" integer NOT NULL,
  "uploaded_by" integer NOT NULL,
  "filename" text NOT NULL,
  "file_url" text NOT NULL,
  "file_size" integer NOT NULL,
  "mime_type" text NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: pipelines
CREATE TABLE IF NOT EXISTS "pipelines" (
  "id" integer NOT NULL DEFAULT nextval('pipelines_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "is_default" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: properties
CREATE TABLE IF NOT EXISTS "properties" (
  "id" integer NOT NULL DEFAULT nextval('properties_id_seq'::regclass),
  "company_id" integer NOT NULL,
  "name" text NOT NULL,
  "type" text NOT NULL DEFAULT 'house'::property_type,
  "status" text DEFAULT 'available'::property_status,
  "reference_code" text,
  "description" text,
  "sales_speech" text,
  "quick_description" text,
  "price" integer,
  "currency" text DEFAULT 'USD'::text,
  "price_per_m2" numeric,
  "negotiable" boolean DEFAULT true,
  "address" text,
  "city" text,
  "state" text,
  "country" text,
  "zip_code" text,
  "neighborhood" text,
  "latitude" numeric,
  "longitude" numeric,
  "bedrooms" integer,
  "bathrooms" integer,
  "half_bathrooms" integer DEFAULT 0,
  "parking_spaces" integer DEFAULT 0,
  "area_m2" numeric,
  "area_ft2" numeric,
  "lot_size_m2" numeric,
  "construction_year" integer,
  "floors" integer DEFAULT 1,
  "features" jsonb DEFAULT '{}'::jsonb,
  "files" jsonb DEFAULT '[]'::jsonb,
  "tags" text[],
  "assigned_agent_id" integer,
  "created_by" integer,
  "slug" text,
  "is_featured" boolean DEFAULT false,
  "views_count" integer DEFAULT 0,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: deal_properties
CREATE TABLE IF NOT EXISTS "deal_properties" (
  "id" integer NOT NULL DEFAULT nextval('deal_properties_id_seq'::regclass),
  "deal_id" integer NOT NULL,
  "property_id" integer NOT NULL,
  "created_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: property_media
CREATE TABLE IF NOT EXISTS "property_media" (
  "id" integer NOT NULL DEFAULT nextval('property_media_id_seq'::regclass),
  "property_id" integer NOT NULL,
  "media_type" text NOT NULL,
  "file_url" text NOT NULL,
  "file_name" text NOT NULL,
  "file_size" integer NOT NULL,
  "mime_type" text,
  "order_num" integer DEFAULT 0,
  "is_flyer" boolean DEFAULT false,
  "is_primary" boolean DEFAULT false,
  "uploaded_by" integer,
  "created_at" timestamp without time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Constraints & Foreign Keys
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contacts_company_id_fkey') THEN
    ALTER TABLE "contacts" ADD CONSTRAINT "contacts_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contacts_assigned_to_user_id_fkey') THEN
    ALTER TABLE "contacts" ADD CONSTRAINT "contacts_assigned_to_user_id_fkey" FOREIGN KEY ("assigned_to_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'role_permissions_company_id_role_key') THEN
    ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_company_id_role_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'role_permissions_company_id_role_key') THEN
    ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_company_id_role_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'role_permissions_company_id_role_key') THEN
    ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_company_id_role_key" UNIQUE ("role");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'role_permissions_company_id_role_key') THEN
    ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_company_id_role_key" UNIQUE ("role");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'role_permissions_company_id_fkey') THEN
    ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversations_company_id_fkey') THEN
    ALTER TABLE "conversations" ADD CONSTRAINT "conversations_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversations_contact_id_fkey') THEN
    ALTER TABLE "conversations" ADD CONSTRAINT "conversations_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversations_channel_id_fkey') THEN
    ALTER TABLE "conversations" ADD CONSTRAINT "conversations_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversations_assigned_to_user_id_fkey') THEN
    ALTER TABLE "conversations" ADD CONSTRAINT "conversations_assigned_to_user_id_fkey" FOREIGN KEY ("assigned_to_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'companies_slug_key') THEN
    ALTER TABLE "companies" ADD CONSTRAINT "companies_slug_key" UNIQUE ("slug");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'companies_subdomain_key') THEN
    ALTER TABLE "companies" ADD CONSTRAINT "companies_subdomain_key" UNIQUE ("subdomain");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'companies_plan_id_fkey') THEN
    ALTER TABLE "companies" ADD CONSTRAINT "companies_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_username_key') THEN
    ALTER TABLE "users" ADD CONSTRAINT "users_username_key" UNIQUE ("username");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_company_id_fkey') THEN
    ALTER TABLE "users" ADD CONSTRAINT "users_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_conversation_id_participant_jid_key') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_conversation_id_participant_jid_key" UNIQUE ("conversation_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_conversation_id_participant_jid_key') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_conversation_id_participant_jid_key" UNIQUE ("conversation_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_conversation_id_participant_jid_key') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_conversation_id_participant_jid_key" UNIQUE ("participant_jid");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_conversation_id_participant_jid_key') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_conversation_id_participant_jid_key" UNIQUE ("participant_jid");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_conversation_id_fkey') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'group_participants_contact_id_fkey') THEN
    ALTER TABLE "group_participants" ADD CONSTRAINT "group_participants_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notes_contact_id_fkey') THEN
    ALTER TABLE "notes" ADD CONSTRAINT "notes_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notes_created_by_id_fkey') THEN
    ALTER TABLE "notes" ADD CONSTRAINT "notes_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flows_user_id_fkey') THEN
    ALTER TABLE "flows" ADD CONSTRAINT "flows_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flows_company_id_fkey') THEN
    ALTER TABLE "flows" ADD CONSTRAINT "flows_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_assignments_flow_id_fkey') THEN
    ALTER TABLE "flow_assignments" ADD CONSTRAINT "flow_assignments_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_assignments_channel_id_fkey') THEN
    ALTER TABLE "flow_assignments" ADD CONSTRAINT "flow_assignments_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_executions_execution_id_key') THEN
    ALTER TABLE "flow_executions" ADD CONSTRAINT "flow_executions_execution_id_key" UNIQUE ("execution_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_executions_flow_id_fkey') THEN
    ALTER TABLE "flow_executions" ADD CONSTRAINT "flow_executions_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_executions_conversation_id_fkey') THEN
    ALTER TABLE "flow_executions" ADD CONSTRAINT "flow_executions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_executions_contact_id_fkey') THEN
    ALTER TABLE "flow_executions" ADD CONSTRAINT "flow_executions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_executions_company_id_fkey') THEN
    ALTER TABLE "flow_executions" ADD CONSTRAINT "flow_executions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_sessions_session_id_key') THEN
    ALTER TABLE "flow_sessions" ADD CONSTRAINT "flow_sessions_session_id_key" UNIQUE ("session_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_sessions_flow_id_fkey') THEN
    ALTER TABLE "flow_sessions" ADD CONSTRAINT "flow_sessions_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_sessions_conversation_id_fkey') THEN
    ALTER TABLE "flow_sessions" ADD CONSTRAINT "flow_sessions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_sessions_contact_id_fkey') THEN
    ALTER TABLE "flow_sessions" ADD CONSTRAINT "flow_sessions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_sessions_company_id_fkey') THEN
    ALTER TABLE "flow_sessions" ADD CONSTRAINT "flow_sessions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_variables_session_id_variable_key_key') THEN
    ALTER TABLE "flow_session_variables" ADD CONSTRAINT "flow_session_variables_session_id_variable_key_key" UNIQUE ("session_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_variables_session_id_variable_key_key') THEN
    ALTER TABLE "flow_session_variables" ADD CONSTRAINT "flow_session_variables_session_id_variable_key_key" UNIQUE ("session_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_variables_session_id_variable_key_key') THEN
    ALTER TABLE "flow_session_variables" ADD CONSTRAINT "flow_session_variables_session_id_variable_key_key" UNIQUE ("variable_key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_variables_session_id_variable_key_key') THEN
    ALTER TABLE "flow_session_variables" ADD CONSTRAINT "flow_session_variables_session_id_variable_key_key" UNIQUE ("variable_key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_variables_session_id_fkey') THEN
    ALTER TABLE "flow_session_variables" ADD CONSTRAINT "flow_session_variables_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "flow_sessions"("session_id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_step_executions_flow_execution_id_fkey') THEN
    ALTER TABLE "flow_step_executions" ADD CONSTRAINT "flow_step_executions_flow_execution_id_fkey" FOREIGN KEY ("flow_execution_id") REFERENCES "flow_executions"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_step_executions_session_id_fkey') THEN
    ALTER TABLE "flow_step_executions" ADD CONSTRAINT "flow_step_executions_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "flow_sessions"("session_id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_cursors_session_id_key') THEN
    ALTER TABLE "flow_session_cursors" ADD CONSTRAINT "flow_session_cursors_session_id_key" UNIQUE ("session_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'flow_session_cursors_session_id_fkey') THEN
    ALTER TABLE "flow_session_cursors" ADD CONSTRAINT "flow_session_cursors_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "flow_sessions"("session_id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_company_id_name_key') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_company_id_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_company_id_name_key') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_company_id_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_company_id_name_key') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_company_id_name_key" UNIQUE ("name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_company_id_name_key') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_company_id_name_key" UNIQUE ("name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_company_id_fkey') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_templates_created_by_fkey') THEN
    ALTER TABLE "follow_up_templates" ADD CONSTRAINT "follow_up_templates_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'team_invitations_token_key') THEN
    ALTER TABLE "team_invitations" ADD CONSTRAINT "team_invitations_token_key" UNIQUE ("token");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'team_invitations_invited_by_user_id_fkey') THEN
    ALTER TABLE "team_invitations" ADD CONSTRAINT "team_invitations_invited_by_user_id_fkey" FOREIGN KEY ("invited_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'team_invitations_company_id_fkey') THEN
    ALTER TABLE "team_invitations" ADD CONSTRAINT "team_invitations_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deals_company_id_fkey') THEN
    ALTER TABLE "deals" ADD CONSTRAINT "deals_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deals_contact_id_fkey') THEN
    ALTER TABLE "deals" ADD CONSTRAINT "deals_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deals_stage_id_fkey') THEN
    ALTER TABLE "deals" ADD CONSTRAINT "deals_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "pipeline_stages"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deals_assigned_to_user_id_fkey') THEN
    ALTER TABLE "deals" ADD CONSTRAINT "deals_assigned_to_user_id_fkey" FOREIGN KEY ("assigned_to_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_activities_deal_id_fkey') THEN
    ALTER TABLE "deal_activities" ADD CONSTRAINT "deal_activities_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_activities_user_id_fkey') THEN
    ALTER TABLE "deal_activities" ADD CONSTRAINT "deal_activities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_user_id_fkey') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'google_calendar_tokens_company_id_fkey') THEN
    ALTER TABLE "google_calendar_tokens" ADD CONSTRAINT "google_calendar_tokens_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'app_settings_key_key') THEN
    ALTER TABLE "app_settings" ADD CONSTRAINT "app_settings_key_key" UNIQUE ("key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_settings_company_id_key_key') THEN
    ALTER TABLE "company_settings" ADD CONSTRAINT "company_settings_company_id_key_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_settings_company_id_key_key') THEN
    ALTER TABLE "company_settings" ADD CONSTRAINT "company_settings_company_id_key_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_settings_company_id_key_key') THEN
    ALTER TABLE "company_settings" ADD CONSTRAINT "company_settings_company_id_key_key" UNIQUE ("key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_settings_company_id_key_key') THEN
    ALTER TABLE "company_settings" ADD CONSTRAINT "company_settings_company_id_key_key" UNIQUE ("key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_settings_company_id_fkey') THEN
    ALTER TABLE "company_settings" ADD CONSTRAINT "company_settings_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pipeline_stages_company_id_fkey') THEN
    ALTER TABLE "pipeline_stages" ADD CONSTRAINT "pipeline_stages_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pipeline_stages_pipeline_id_fkey') THEN
    ALTER TABLE "pipeline_stages" ADD CONSTRAINT "pipeline_stages_pipeline_id_fkey" FOREIGN KEY ("pipeline_id") REFERENCES "pipelines"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payment_transactions_company_id_fkey') THEN
    ALTER TABLE "payment_transactions" ADD CONSTRAINT "payment_transactions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payment_transactions_plan_id_fkey') THEN
    ALTER TABLE "payment_transactions" ADD CONSTRAINT "payment_transactions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payment_transactions_coupon_code_id_fkey') THEN
    ALTER TABLE "payment_transactions" ADD CONSTRAINT "payment_transactions_coupon_code_id_fkey" FOREIGN KEY ("coupon_code_id") REFERENCES "coupon_codes"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'password_reset_tokens_token_key') THEN
    ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_token_key" UNIQUE ("token");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'password_reset_tokens_user_id_fkey') THEN
    ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_namespaces_name_key') THEN
    ALTER TABLE "translation_namespaces" ADD CONSTRAINT "translation_namespaces_name_key" UNIQUE ("name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_keys_namespace_id_key_key') THEN
    ALTER TABLE "translation_keys" ADD CONSTRAINT "translation_keys_namespace_id_key_key" UNIQUE ("namespace_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_keys_namespace_id_key_key') THEN
    ALTER TABLE "translation_keys" ADD CONSTRAINT "translation_keys_namespace_id_key_key" UNIQUE ("namespace_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_keys_namespace_id_key_key') THEN
    ALTER TABLE "translation_keys" ADD CONSTRAINT "translation_keys_namespace_id_key_key" UNIQUE ("key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_keys_namespace_id_key_key') THEN
    ALTER TABLE "translation_keys" ADD CONSTRAINT "translation_keys_namespace_id_key_key" UNIQUE ("key");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translation_keys_namespace_id_fkey') THEN
    ALTER TABLE "translation_keys" ADD CONSTRAINT "translation_keys_namespace_id_fkey" FOREIGN KEY ("namespace_id") REFERENCES "translation_namespaces"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_key_id_language_id_key') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_key_id_language_id_key" UNIQUE ("key_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_key_id_language_id_key') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_key_id_language_id_key" UNIQUE ("key_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_key_id_language_id_key') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_key_id_language_id_key" UNIQUE ("language_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_key_id_language_id_key') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_key_id_language_id_key" UNIQUE ("language_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_key_id_fkey') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_key_id_fkey" FOREIGN KEY ("key_id") REFERENCES "translation_keys"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'translations_language_id_fkey') THEN
    ALTER TABLE "translations" ADD CONSTRAINT "translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "languages"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'languages_code_key') THEN
    ALTER TABLE "languages" ADD CONSTRAINT "languages_code_key" UNIQUE ("code");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_segments_company_id_fkey') THEN
    ALTER TABLE "contact_segments" ADD CONSTRAINT "contact_segments_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_segments_created_by_id_fkey') THEN
    ALTER TABLE "contact_segments" ADD CONSTRAINT "contact_segments_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'backup_logs_log_id_key') THEN
    ALTER TABLE "backup_logs" ADD CONSTRAINT "backup_logs_log_id_key" UNIQUE ("log_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_templates_company_id_fkey') THEN
    ALTER TABLE "campaign_templates" ADD CONSTRAINT "campaign_templates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_templates_created_by_id_fkey') THEN
    ALTER TABLE "campaign_templates" ADD CONSTRAINT "campaign_templates_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_templates_connection_id_fkey') THEN
    ALTER TABLE "campaign_templates" ADD CONSTRAINT "campaign_templates_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_company_id_fkey') THEN
    ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_created_by_id_fkey') THEN
    ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_template_id_fkey') THEN
    ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "campaign_templates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_segment_id_fkey') THEN
    ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "contact_segments"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_channel_id_fkey') THEN
    ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_campaign_id_contact_id_key') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_campaign_id_contact_id_key" UNIQUE ("campaign_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_campaign_id_contact_id_key') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_campaign_id_contact_id_key" UNIQUE ("campaign_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_campaign_id_contact_id_key') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_campaign_id_contact_id_key" UNIQUE ("contact_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_campaign_id_contact_id_key') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_campaign_id_contact_id_key" UNIQUE ("contact_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_campaign_id_fkey') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_contact_id_fkey') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_recipients_conversation_id_fkey') THEN
    ALTER TABLE "campaign_recipients" ADD CONSTRAINT "campaign_recipients_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_messages_campaign_id_fkey') THEN
    ALTER TABLE "campaign_messages" ADD CONSTRAINT "campaign_messages_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_messages_recipient_id_fkey') THEN
    ALTER TABLE "campaign_messages" ADD CONSTRAINT "campaign_messages_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "campaign_recipients"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_messages_message_id_fkey') THEN
    ALTER TABLE "campaign_messages" ADD CONSTRAINT "campaign_messages_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_analytics_campaign_id_fkey') THEN
    ALTER TABLE "campaign_analytics" ADD CONSTRAINT "campaign_analytics_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_company_id_fkey') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_channel_id_fkey') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_company_id_phone_number_key') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_company_id_phone_number_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_company_id_phone_number_key') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_company_id_phone_number_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_company_id_phone_number_key') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_company_id_phone_number_key" UNIQUE ("phone_number");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_accounts_company_id_phone_number_key') THEN
    ALTER TABLE "whatsapp_accounts" ADD CONSTRAINT "whatsapp_accounts_company_id_phone_number_key" UNIQUE ("phone_number");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_account_logs_account_id_fkey') THEN
    ALTER TABLE "whatsapp_account_logs" ADD CONSTRAINT "whatsapp_account_logs_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "whatsapp_accounts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_queue_campaign_id_fkey') THEN
    ALTER TABLE "campaign_queue" ADD CONSTRAINT "campaign_queue_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_queue_recipient_id_fkey') THEN
    ALTER TABLE "campaign_queue" ADD CONSTRAINT "campaign_queue_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "campaign_recipients"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaign_queue_account_id_fkey') THEN
    ALTER TABLE "campaign_queue" ADD CONSTRAINT "campaign_queue_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_execution_log_schedule_id_fkey') THEN
    ALTER TABLE "follow_up_execution_log" ADD CONSTRAINT "follow_up_execution_log_schedule_id_fkey" FOREIGN KEY ("schedule_id") REFERENCES "follow_up_schedules"("schedule_id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dialog_360_clients_client_id_key') THEN
    ALTER TABLE "dialog_360_clients" ADD CONSTRAINT "dialog_360_clients_client_id_key" UNIQUE ("client_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dialog_360_clients_company_id_fkey') THEN
    ALTER TABLE "dialog_360_clients" ADD CONSTRAINT "dialog_360_clients_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'meta_whatsapp_clients_business_account_id_key') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD CONSTRAINT "meta_whatsapp_clients_business_account_id_key" UNIQUE ("business_account_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'meta_whatsapp_clients_company_id_fkey') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD CONSTRAINT "meta_whatsapp_clients_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dialog_360_channels_channel_id_key') THEN
    ALTER TABLE "dialog_360_channels" ADD CONSTRAINT "dialog_360_channels_channel_id_key" UNIQUE ("channel_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dialog_360_channels_client_id_fkey') THEN
    ALTER TABLE "dialog_360_channels" ADD CONSTRAINT "dialog_360_channels_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "dialog_360_clients"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'partner_configurations_provider_key') THEN
    ALTER TABLE "partner_configurations" ADD CONSTRAINT "partner_configurations_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'meta_whatsapp_phone_numbers_phone_number_id_key') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD CONSTRAINT "meta_whatsapp_phone_numbers_phone_number_id_key" UNIQUE ("phone_number_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'meta_whatsapp_phone_numbers_client_id_fkey') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD CONSTRAINT "meta_whatsapp_phone_numbers_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "meta_whatsapp_clients"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_keys_key_hash_key') THEN
    ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_key_hash_key" UNIQUE ("key_hash");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_keys_company_id_fkey') THEN
    ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_keys_user_id_fkey') THEN
    ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_usage_api_key_id_fkey') THEN
    ALTER TABLE "api_usage" ADD CONSTRAINT "api_usage_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_keys"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_usage_company_id_fkey') THEN
    ALTER TABLE "api_usage" ADD CONSTRAINT "api_usage_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_usage_request_id_key') THEN
    ALTER TABLE "api_usage" ADD CONSTRAINT "api_usage_request_id_key" UNIQUE ("request_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'api_rate_limits_api_key_id_fkey') THEN
    ALTER TABLE "api_rate_limits" ADD CONSTRAINT "api_rate_limits_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_keys"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'email_attachments_message_id_fkey') THEN
    ALTER TABLE "email_attachments" ADD CONSTRAINT "email_attachments_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'email_configs_channel_connection_id_fkey') THEN
    ALTER TABLE "email_configs" ADD CONSTRAINT "email_configs_channel_connection_id_fkey" FOREIGN KEY ("channel_connection_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_user_id_provider_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_user_id_provider_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_user_id_provider_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_user_id_provider_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_user_id_provider_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_user_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_user_id_provider_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_user_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_provider_provider_user_id_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_provider_provider_user_id_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_provider_provider_user_id_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_provider_provider_user_id_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_provider_provider_user_id_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_provider_provider_user_id_key" UNIQUE ("provider_user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_provider_provider_user_id_key') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_provider_provider_user_id_key" UNIQUE ("provider_user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_social_accounts_user_id_fkey') THEN
    ALTER TABLE "user_social_accounts" ADD CONSTRAINT "user_social_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliates_affiliate_code_key') THEN
    ALTER TABLE "affiliates" ADD CONSTRAINT "affiliates_affiliate_code_key" UNIQUE ("affiliate_code");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliates_company_id_fkey') THEN
    ALTER TABLE "affiliates" ADD CONSTRAINT "affiliates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliates_user_id_fkey') THEN
    ALTER TABLE "affiliates" ADD CONSTRAINT "affiliates_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliates_approved_by_fkey') THEN
    ALTER TABLE "affiliates" ADD CONSTRAINT "affiliates_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'messages_conversation_id_fkey') THEN
    ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_commission_structures_company_id_fkey') THEN
    ALTER TABLE "affiliate_commission_structures" ADD CONSTRAINT "affiliate_commission_structures_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_commission_structures_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_commission_structures" ADD CONSTRAINT "affiliate_commission_structures_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_commission_structures_plan_id_fkey') THEN
    ALTER TABLE "affiliate_commission_structures" ADD CONSTRAINT "affiliate_commission_structures_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_referrals_company_id_fkey') THEN
    ALTER TABLE "affiliate_referrals" ADD CONSTRAINT "affiliate_referrals_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_referrals_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_referrals" ADD CONSTRAINT "affiliate_referrals_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_referrals_referred_company_id_fkey') THEN
    ALTER TABLE "affiliate_referrals" ADD CONSTRAINT "affiliate_referrals_referred_company_id_fkey" FOREIGN KEY ("referred_company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_referrals_referred_user_id_fkey') THEN
    ALTER TABLE "affiliate_referrals" ADD CONSTRAINT "affiliate_referrals_referred_user_id_fkey" FOREIGN KEY ("referred_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_referrals_commission_structure_id_fkey') THEN
    ALTER TABLE "affiliate_referrals" ADD CONSTRAINT "affiliate_referrals_commission_structure_id_fkey" FOREIGN KEY ("commission_structure_id") REFERENCES "affiliate_commission_structures"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_payouts_company_id_fkey') THEN
    ALTER TABLE "affiliate_payouts" ADD CONSTRAINT "affiliate_payouts_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_payouts_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_payouts" ADD CONSTRAINT "affiliate_payouts_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_payouts_processed_by_fkey') THEN
    ALTER TABLE "affiliate_payouts" ADD CONSTRAINT "affiliate_payouts_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("period_type");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("period_type");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("period_type");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_affiliate_id_date_period_typ_key') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_affiliate_id_date_period_typ_key" UNIQUE ("period_type");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_company_id_fkey') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_analytics_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_analytics" ADD CONSTRAINT "affiliate_analytics_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_clicks_company_id_fkey') THEN
    ALTER TABLE "affiliate_clicks" ADD CONSTRAINT "affiliate_clicks_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_clicks_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_clicks" ADD CONSTRAINT "affiliate_clicks_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_clicks_referral_id_fkey') THEN
    ALTER TABLE "affiliate_clicks" ADD CONSTRAINT "affiliate_clicks_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "affiliate_referrals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("parent_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("parent_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("parent_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("child_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("child_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_parent_affiliate_id_chil_key') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_parent_affiliate_id_chil_key" UNIQUE ("child_affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_company_id_fkey') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_parent_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_parent_affiliate_id_fkey" FOREIGN KEY ("parent_affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_relationships_child_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_relationships" ADD CONSTRAINT "affiliate_relationships_child_affiliate_id_fkey" FOREIGN KEY ("child_affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_applications_email_key') THEN
    ALTER TABLE "affiliate_applications" ADD CONSTRAINT "affiliate_applications_email_key" UNIQUE ("email");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_applications_reviewed_by_fkey') THEN
    ALTER TABLE "affiliate_applications" ADD CONSTRAINT "affiliate_applications_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_codes_code_key') THEN
    ALTER TABLE "coupon_codes" ADD CONSTRAINT "coupon_codes_code_key" UNIQUE ("code");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_codes_company_id_fkey') THEN
    ALTER TABLE "coupon_codes" ADD CONSTRAINT "coupon_codes_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_codes_created_by_fkey') THEN
    ALTER TABLE "coupon_codes" ADD CONSTRAINT "coupon_codes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_usage_coupon_id_fkey') THEN
    ALTER TABLE "coupon_usage" ADD CONSTRAINT "coupon_usage_coupon_id_fkey" FOREIGN KEY ("coupon_id") REFERENCES "coupon_codes"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_usage_company_id_fkey') THEN
    ALTER TABLE "coupon_usage" ADD CONSTRAINT "coupon_usage_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_usage_user_id_fkey') THEN
    ALTER TABLE "coupon_usage" ADD CONSTRAINT "coupon_usage_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_usage_plan_id_fkey') THEN
    ALTER TABLE "coupon_usage" ADD CONSTRAINT "coupon_usage_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'coupon_usage_payment_transaction_id_fkey') THEN
    ALTER TABLE "coupon_usage" ADD CONSTRAINT "coupon_usage_payment_transaction_id_fkey" FOREIGN KEY ("payment_transaction_id") REFERENCES "payment_transactions"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_company_id_affiliate_id_key') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_company_id_affiliate_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_company_id_affiliate_id_key') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_company_id_affiliate_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_company_id_affiliate_id_key') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_company_id_affiliate_id_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_company_id_affiliate_id_key') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_company_id_affiliate_id_key" UNIQUE ("affiliate_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_company_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_balance_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD CONSTRAINT "affiliate_earnings_balance_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_transactions_company_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD CONSTRAINT "affiliate_earnings_transactions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_transactions_affiliate_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD CONSTRAINT "affiliate_earnings_transactions_affiliate_id_fkey" FOREIGN KEY ("affiliate_id") REFERENCES "affiliates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_transactions_referral_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD CONSTRAINT "affiliate_earnings_transactions_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "affiliate_referrals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_transactions_payment_transaction_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD CONSTRAINT "affiliate_earnings_transactions_payment_transaction_id_fkey" FOREIGN KEY ("payment_transaction_id") REFERENCES "payment_transactions"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'affiliate_earnings_transactions_payout_id_fkey') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD CONSTRAINT "affiliate_earnings_transactions_payout_id_fkey" FOREIGN KEY ("payout_id") REFERENCES "affiliate_payouts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_preferences_company_id_key') THEN
    ALTER TABLE "company_ai_preferences" ADD CONSTRAINT "company_ai_preferences_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_preferences_company_id_fkey') THEN
    ALTER TABLE "company_ai_preferences" ADD CONSTRAINT "company_ai_preferences_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ai_credential_usage_company_id_fkey') THEN
    ALTER TABLE "ai_credential_usage" ADD CONSTRAINT "ai_credential_usage_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ai_credential_usage_conversation_id_fkey') THEN
    ALTER TABLE "ai_credential_usage" ADD CONSTRAINT "ai_credential_usage_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ai_credential_usage_flow_id_fkey') THEN
    ALTER TABLE "ai_credential_usage" ADD CONSTRAINT "ai_credential_usage_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_provider_configs_plan_id_provider_key') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD CONSTRAINT "plan_ai_provider_configs_plan_id_provider_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_provider_configs_plan_id_provider_key') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD CONSTRAINT "plan_ai_provider_configs_plan_id_provider_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_provider_configs_plan_id_provider_key') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD CONSTRAINT "plan_ai_provider_configs_plan_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_provider_configs_plan_id_provider_key') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD CONSTRAINT "plan_ai_provider_configs_plan_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_provider_configs_plan_id_fkey') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD CONSTRAINT "plan_ai_provider_configs_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("plan_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_year");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_month");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_plan_id_provider_usage_ye_key" UNIQUE ("usage_date");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_company_id_fkey') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_usage_tracking_plan_id_fkey') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD CONSTRAINT "plan_ai_usage_tracking_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_billing_events_company_id_fkey') THEN
    ALTER TABLE "plan_ai_billing_events" ADD CONSTRAINT "plan_ai_billing_events_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'plan_ai_billing_events_plan_id_fkey') THEN
    ALTER TABLE "plan_ai_billing_events" ADD CONSTRAINT "plan_ai_billing_events_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_ai_credentials_provider_is_default_key') THEN
    ALTER TABLE "system_ai_credentials" ADD CONSTRAINT "system_ai_credentials_provider_is_default_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_ai_credentials_provider_is_default_key') THEN
    ALTER TABLE "system_ai_credentials" ADD CONSTRAINT "system_ai_credentials_provider_is_default_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_ai_credentials_provider_is_default_key') THEN
    ALTER TABLE "system_ai_credentials" ADD CONSTRAINT "system_ai_credentials_provider_is_default_key" UNIQUE ("is_default");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_ai_credentials_provider_is_default_key') THEN
    ALTER TABLE "system_ai_credentials" ADD CONSTRAINT "system_ai_credentials_provider_is_default_key" UNIQUE ("is_default");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_credentials_company_id_provider_key') THEN
    ALTER TABLE "company_ai_credentials" ADD CONSTRAINT "company_ai_credentials_company_id_provider_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_credentials_company_id_provider_key') THEN
    ALTER TABLE "company_ai_credentials" ADD CONSTRAINT "company_ai_credentials_company_id_provider_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_credentials_company_id_provider_key') THEN
    ALTER TABLE "company_ai_credentials" ADD CONSTRAINT "company_ai_credentials_company_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_credentials_company_id_provider_key') THEN
    ALTER TABLE "company_ai_credentials" ADD CONSTRAINT "company_ai_credentials_company_id_provider_key" UNIQUE ("provider");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_ai_credentials_company_id_fkey') THEN
    ALTER TABLE "company_ai_credentials" ADD CONSTRAINT "company_ai_credentials_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_events_company_id_fkey') THEN
    ALTER TABLE "subscription_events" ADD CONSTRAINT "subscription_events_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_usage_tracking_company_id_metric_name_key') THEN
    ALTER TABLE "subscription_usage_tracking" ADD CONSTRAINT "subscription_usage_tracking_company_id_metric_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_usage_tracking_company_id_metric_name_key') THEN
    ALTER TABLE "subscription_usage_tracking" ADD CONSTRAINT "subscription_usage_tracking_company_id_metric_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_usage_tracking_company_id_metric_name_key') THEN
    ALTER TABLE "subscription_usage_tracking" ADD CONSTRAINT "subscription_usage_tracking_company_id_metric_name_key" UNIQUE ("metric_name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_usage_tracking_company_id_metric_name_key') THEN
    ALTER TABLE "subscription_usage_tracking" ADD CONSTRAINT "subscription_usage_tracking_company_id_metric_name_key" UNIQUE ("metric_name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_usage_tracking_company_id_fkey') THEN
    ALTER TABLE "subscription_usage_tracking" ADD CONSTRAINT "subscription_usage_tracking_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dunning_management_company_id_fkey') THEN
    ALTER TABLE "dunning_management" ADD CONSTRAINT "dunning_management_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dunning_management_payment_transaction_id_fkey') THEN
    ALTER TABLE "dunning_management" ADD CONSTRAINT "dunning_management_payment_transaction_id_fkey" FOREIGN KEY ("payment_transaction_id") REFERENCES "payment_transactions"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plan_changes_company_id_fkey') THEN
    ALTER TABLE "subscription_plan_changes" ADD CONSTRAINT "subscription_plan_changes_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plan_changes_from_plan_id_fkey') THEN
    ALTER TABLE "subscription_plan_changes" ADD CONSTRAINT "subscription_plan_changes_from_plan_id_fkey" FOREIGN KEY ("from_plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plan_changes_to_plan_id_fkey') THEN
    ALTER TABLE "subscription_plan_changes" ADD CONSTRAINT "subscription_plan_changes_to_plan_id_fkey" FOREIGN KEY ("to_plan_id") REFERENCES "plans"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subscription_notifications_company_id_fkey') THEN
    ALTER TABLE "subscription_notifications" ADD CONSTRAINT "subscription_notifications_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_schedule_id_key') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_schedule_id_key" UNIQUE ("schedule_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_session_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "flow_sessions"("session_id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_flow_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_conversation_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_contact_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_company_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'follow_up_schedules_channel_connection_id_fkey') THEN
    ALTER TABLE "follow_up_schedules" ADD CONSTRAINT "follow_up_schedules_channel_connection_id_fkey" FOREIGN KEY ("channel_connection_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'website_templates_created_by_id_fkey') THEN
    ALTER TABLE "website_templates" ADD CONSTRAINT "website_templates_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'websites_slug_key') THEN
    ALTER TABLE "websites" ADD CONSTRAINT "websites_slug_key" UNIQUE ("slug");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'websites_template_id_fkey') THEN
    ALTER TABLE "websites" ADD CONSTRAINT "websites_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "website_templates"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'websites_created_by_id_fkey') THEN
    ALTER TABLE "websites" ADD CONSTRAINT "websites_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_documents_company_id_fkey') THEN
    ALTER TABLE "knowledge_base_documents" ADD CONSTRAINT "knowledge_base_documents_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'website_assets_website_id_fkey') THEN
    ALTER TABLE "website_assets" ADD CONSTRAINT "website_assets_website_id_fkey" FOREIGN KEY ("website_id") REFERENCES "websites"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'quick_reply_templates_company_id_fkey') THEN
    ALTER TABLE "quick_reply_templates" ADD CONSTRAINT "quick_reply_templates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'quick_reply_templates_created_by_id_fkey') THEN
    ALTER TABLE "quick_reply_templates" ADD CONSTRAINT "quick_reply_templates_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_chunks_document_id_fkey') THEN
    ALTER TABLE "knowledge_base_chunks" ADD CONSTRAINT "knowledge_base_chunks_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "knowledge_base_documents"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_company_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_company_id_node_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_company_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_company_id_node_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_company_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_company_id_node_id_key" UNIQUE ("node_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_company_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_company_id_node_id_key" UNIQUE ("node_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_company_id_fkey') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_configs_flow_id_fkey') THEN
    ALTER TABLE "knowledge_base_configs" ADD CONSTRAINT "knowledge_base_configs_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_document_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_document_id_node_id_key" UNIQUE ("document_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_document_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_document_id_node_id_key" UNIQUE ("document_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_document_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_document_id_node_id_key" UNIQUE ("node_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_document_id_node_id_key') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_document_id_node_id_key" UNIQUE ("node_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_document_id_fkey') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "knowledge_base_documents"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_company_id_fkey') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_document_nodes_flow_id_fkey') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD CONSTRAINT "knowledge_base_document_nodes_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_usage_company_id_fkey') THEN
    ALTER TABLE "knowledge_base_usage" ADD CONSTRAINT "knowledge_base_usage_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'knowledge_base_usage_document_id_fkey') THEN
    ALTER TABLE "knowledge_base_usage" ADD CONSTRAINT "knowledge_base_usage_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "knowledge_base_documents"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_documents_contact_id_fkey') THEN
    ALTER TABLE "contact_documents" ADD CONSTRAINT "contact_documents_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_documents_uploaded_by_fkey') THEN
    ALTER TABLE "contact_documents" ADD CONSTRAINT "contact_documents_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_appointments_contact_id_fkey') THEN
    ALTER TABLE "contact_appointments" ADD CONSTRAINT "contact_appointments_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_appointments_created_by_fkey') THEN
    ALTER TABLE "contact_appointments" ADD CONSTRAINT "contact_appointments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_user_id_fkey') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'zoho_calendar_tokens_company_id_fkey') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD CONSTRAINT "zoho_calendar_tokens_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'history_sync_batches_batch_id_key') THEN
    ALTER TABLE "history_sync_batches" ADD CONSTRAINT "history_sync_batches_batch_id_key" UNIQUE ("batch_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'history_sync_batches_connection_id_fkey') THEN
    ALTER TABLE "history_sync_batches" ADD CONSTRAINT "history_sync_batches_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'history_sync_batches_company_id_fkey') THEN
    ALTER TABLE "history_sync_batches" ADD CONSTRAINT "history_sync_batches_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_audit_logs_company_id_fkey') THEN
    ALTER TABLE "contact_audit_logs" ADD CONSTRAINT "contact_audit_logs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_audit_logs_contact_id_fkey') THEN
    ALTER TABLE "contact_audit_logs" ADD CONSTRAINT "contact_audit_logs_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_audit_logs_user_id_fkey') THEN
    ALTER TABLE "contact_audit_logs" ADD CONSTRAINT "contact_audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_user_id_company_id_key" UNIQUE ("user_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_user_id_company_id_key') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_user_id_company_id_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_user_id_fkey') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calendly_calendar_tokens_company_id_fkey') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD CONSTRAINT "calendly_calendar_tokens_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbox_restores_company_id_fkey') THEN
    ALTER TABLE "inbox_restores" ADD CONSTRAINT "inbox_restores_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbox_restores_backup_id_fkey') THEN
    ALTER TABLE "inbox_restores" ADD CONSTRAINT "inbox_restores_backup_id_fkey" FOREIGN KEY ("backup_id") REFERENCES "inbox_backups"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbox_restores_restored_by_user_id_fkey') THEN
    ALTER TABLE "inbox_restores" ADD CONSTRAINT "inbox_restores_restored_by_user_id_fkey" FOREIGN KEY ("restored_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'backup_schedules_company_id_fkey') THEN
    ALTER TABLE "backup_schedules" ADD CONSTRAINT "backup_schedules_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'backup_schedules_created_by_user_id_fkey') THEN
    ALTER TABLE "backup_schedules" ADD CONSTRAINT "backup_schedules_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbox_backups_company_id_fkey') THEN
    ALTER TABLE "inbox_backups" ADD CONSTRAINT "inbox_backups_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbox_backups_created_by_user_id_fkey') THEN
    ALTER TABLE "inbox_backups" ADD CONSTRAINT "inbox_backups_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'backup_audit_logs_company_id_fkey') THEN
    ALTER TABLE "backup_audit_logs" ADD CONSTRAINT "backup_audit_logs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'backup_audit_logs_user_id_fkey') THEN
    ALTER TABLE "backup_audit_logs" ADD CONSTRAINT "backup_audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calls_company_id_fkey') THEN
    ALTER TABLE "calls" ADD CONSTRAINT "calls_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calls_channel_id_fkey') THEN
    ALTER TABLE "calls" ADD CONSTRAINT "calls_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calls_contact_id_fkey') THEN
    ALTER TABLE "calls" ADD CONSTRAINT "calls_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'calls_conversation_id_fkey') THEN
    ALTER TABLE "calls" ADD CONSTRAINT "calls_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'task_categories_company_id_fkey') THEN
    ALTER TABLE "task_categories" ADD CONSTRAINT "task_categories_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'task_categories_created_by_fkey') THEN
    ALTER TABLE "task_categories" ADD CONSTRAINT "task_categories_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_scheduled_messages_company_id') THEN
    ALTER TABLE "scheduled_messages" ADD CONSTRAINT "fk_scheduled_messages_company_id" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_scheduled_messages_conversation_id') THEN
    ALTER TABLE "scheduled_messages" ADD CONSTRAINT "fk_scheduled_messages_conversation_id" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_scheduled_messages_channel_id') THEN
    ALTER TABLE "scheduled_messages" ADD CONSTRAINT "fk_scheduled_messages_channel_id" FOREIGN KEY ("channel_id") REFERENCES "channel_connections"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_scheduled_messages_created_by') THEN
    ALTER TABLE "scheduled_messages" ADD CONSTRAINT "fk_scheduled_messages_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tasks_contact_id_fkey') THEN
    ALTER TABLE "contact_tasks" ADD CONSTRAINT "contact_tasks_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tasks_company_id_fkey') THEN
    ALTER TABLE "contact_tasks" ADD CONSTRAINT "contact_tasks_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tasks_created_by_fkey') THEN
    ALTER TABLE "contact_tasks" ADD CONSTRAINT "contact_tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tasks_updated_by_fkey') THEN
    ALTER TABLE "contact_tasks" ADD CONSTRAINT "contact_tasks_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'whatsapp_proxy_servers_company_id_fkey') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD CONSTRAINT "whatsapp_proxy_servers_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'channel_connections_user_id_fkey') THEN
    ALTER TABLE "channel_connections" ADD CONSTRAINT "channel_connections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'channel_connections_company_id_fkey') THEN
    ALTER TABLE "channel_connections" ADD CONSTRAINT "channel_connections_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'channel_connections_proxy_server_id_fkey') THEN
    ALTER TABLE "channel_connections" ADD CONSTRAINT "channel_connections_proxy_server_id_fkey" FOREIGN KEY ("proxy_server_id") REFERENCES "whatsapp_proxy_servers"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'database_backup_logs_backup_id_fkey') THEN
    ALTER TABLE "database_backup_logs" ADD CONSTRAINT "database_backup_logs_backup_id_fkey" FOREIGN KEY ("backup_id") REFERENCES "database_backups"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_company_page_slug') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "unique_company_page_slug" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_company_page_slug') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "unique_company_page_slug" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_company_page_slug') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "unique_company_page_slug" UNIQUE ("slug");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_company_page_slug') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "unique_company_page_slug" UNIQUE ("slug");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_pages_company_id_fkey') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "company_pages_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'company_pages_author_id_fkey') THEN
    ALTER TABLE "company_pages" ADD CONSTRAINT "company_pages_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tags_company_id_fkey') THEN
    ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tags_company_id_name_key') THEN
    ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tags_company_id_name_key') THEN
    ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_name_key" UNIQUE ("company_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tags_company_id_name_key') THEN
    ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_name_key" UNIQUE ("name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tags_company_id_name_key') THEN
    ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_name_key" UNIQUE ("name");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_contact_id_tag_id_key') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_tag_id_key" UNIQUE ("contact_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_contact_id_tag_id_key') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_tag_id_key" UNIQUE ("contact_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_contact_id_tag_id_key') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_tag_id_key" UNIQUE ("tag_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_contact_id_tag_id_key') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_tag_id_key" UNIQUE ("tag_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_contact_id_fkey') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contact_tags_tag_id_fkey') THEN
    ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sessions_user_id_fkey') THEN
    ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_checklists_deal_id_fkey') THEN
    ALTER TABLE "deal_checklists" ADD CONSTRAINT "deal_checklists_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_checklist_items_completed_by_fkey') THEN
    ALTER TABLE "deal_checklist_items" ADD CONSTRAINT "deal_checklist_items_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_checklist_items_checklist_id_fkey') THEN
    ALTER TABLE "deal_checklist_items" ADD CONSTRAINT "deal_checklist_items_checklist_id_fkey" FOREIGN KEY ("checklist_id") REFERENCES "deal_checklists"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_comments_deal_id_fkey') THEN
    ALTER TABLE "deal_comments" ADD CONSTRAINT "deal_comments_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_comments_user_id_fkey') THEN
    ALTER TABLE "deal_comments" ADD CONSTRAINT "deal_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_attachments_deal_id_fkey') THEN
    ALTER TABLE "deal_attachments" ADD CONSTRAINT "deal_attachments_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_attachments_uploaded_by_fkey') THEN
    ALTER TABLE "deal_attachments" ADD CONSTRAINT "deal_attachments_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_company_id_fkey') THEN
    ALTER TABLE "properties" ADD CONSTRAINT "properties_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_assigned_agent_id_fkey') THEN
    ALTER TABLE "properties" ADD CONSTRAINT "properties_assigned_agent_id_fkey" FOREIGN KEY ("assigned_agent_id") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_created_by_fkey') THEN
    ALTER TABLE "properties" ADD CONSTRAINT "properties_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_properties_property_id_fkey') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "deal_properties_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "properties"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_deal_property') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "unique_deal_property" UNIQUE ("deal_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_deal_property') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "unique_deal_property" UNIQUE ("deal_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_deal_property') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "unique_deal_property" UNIQUE ("property_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_deal_property') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "unique_deal_property" UNIQUE ("property_id");
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'deal_properties_deal_id_fkey') THEN
    ALTER TABLE "deal_properties" ADD CONSTRAINT "deal_properties_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'property_media_property_id_fkey') THEN
    ALTER TABLE "property_media" ADD CONSTRAINT "property_media_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "properties"("id") ON DELETE CASCADE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'property_media_uploaded_by_fkey') THEN
    ALTER TABLE "property_media" ADD CONSTRAINT "property_media_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;

-- Ensure Columns Exist (for existing tables with missing columns)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'id') THEN
    ALTER TABLE "plans" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'name') THEN
    ALTER TABLE "plans" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'description') THEN
    ALTER TABLE "plans" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'price') THEN
    ALTER TABLE "plans" ADD COLUMN "price" numeric;
    ALTER TABLE "plans" ALTER COLUMN "price" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_users') THEN
    ALTER TABLE "plans" ADD COLUMN "max_users" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_users" SET DEFAULT 5;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_contacts') THEN
    ALTER TABLE "plans" ADD COLUMN "max_contacts" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_contacts" SET DEFAULT 1000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_channels') THEN
    ALTER TABLE "plans" ADD COLUMN "max_channels" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_channels" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_flows') THEN
    ALTER TABLE "plans" ADD COLUMN "max_flows" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_flows" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_campaigns') THEN
    ALTER TABLE "plans" ADD COLUMN "max_campaigns" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_campaigns" SET DEFAULT 5;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_campaign_recipients') THEN
    ALTER TABLE "plans" ADD COLUMN "max_campaign_recipients" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_campaign_recipients" SET DEFAULT 1000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'campaign_features') THEN
    ALTER TABLE "plans" ADD COLUMN "campaign_features" jsonb;
    ALTER TABLE "plans" ALTER COLUMN "campaign_features" SET DEFAULT '["basic_campaigns"]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'is_active') THEN
    ALTER TABLE "plans" ADD COLUMN "is_active" boolean;
    ALTER TABLE "plans" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'is_free') THEN
    ALTER TABLE "plans" ADD COLUMN "is_free" boolean;
    ALTER TABLE "plans" ALTER COLUMN "is_free" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'has_trial_period') THEN
    ALTER TABLE "plans" ADD COLUMN "has_trial_period" boolean;
    ALTER TABLE "plans" ALTER COLUMN "has_trial_period" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'trial_days') THEN
    ALTER TABLE "plans" ADD COLUMN "trial_days" integer;
    ALTER TABLE "plans" ALTER COLUMN "trial_days" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'features') THEN
    ALTER TABLE "plans" ADD COLUMN "features" jsonb;
    ALTER TABLE "plans" ALTER COLUMN "features" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'created_at') THEN
    ALTER TABLE "plans" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "plans" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'updated_at') THEN
    ALTER TABLE "plans" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "plans" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'discount_type') THEN
    ALTER TABLE "plans" ADD COLUMN "discount_type" text;
    ALTER TABLE "plans" ALTER COLUMN "discount_type" SET DEFAULT 'none'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'discount_value') THEN
    ALTER TABLE "plans" ADD COLUMN "discount_value" numeric;
    ALTER TABLE "plans" ALTER COLUMN "discount_value" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'discount_duration') THEN
    ALTER TABLE "plans" ADD COLUMN "discount_duration" text;
    ALTER TABLE "plans" ALTER COLUMN "discount_duration" SET DEFAULT 'permanent'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'discount_start_date') THEN
    ALTER TABLE "plans" ADD COLUMN "discount_start_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'discount_end_date') THEN
    ALTER TABLE "plans" ADD COLUMN "discount_end_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'original_price') THEN
    ALTER TABLE "plans" ADD COLUMN "original_price" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_tokens_included') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_tokens_included" integer;
    ALTER TABLE "plans" ALTER COLUMN "ai_tokens_included" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_tokens_monthly_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_tokens_monthly_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_tokens_daily_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_tokens_daily_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_overage_enabled') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_overage_enabled" boolean;
    ALTER TABLE "plans" ALTER COLUMN "ai_overage_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_overage_rate') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_overage_rate" numeric;
    ALTER TABLE "plans" ALTER COLUMN "ai_overage_rate" SET DEFAULT 0.000000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_overage_block_enabled') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_overage_block_enabled" boolean;
    ALTER TABLE "plans" ALTER COLUMN "ai_overage_block_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'ai_billing_enabled') THEN
    ALTER TABLE "plans" ADD COLUMN "ai_billing_enabled" boolean;
    ALTER TABLE "plans" ALTER COLUMN "ai_billing_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'billing_interval') THEN
    ALTER TABLE "plans" ADD COLUMN "billing_interval" text;
    ALTER TABLE "plans" ALTER COLUMN "billing_interval" SET DEFAULT 'month'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'grace_period_days') THEN
    ALTER TABLE "plans" ADD COLUMN "grace_period_days" integer;
    ALTER TABLE "plans" ALTER COLUMN "grace_period_days" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'max_dunning_attempts') THEN
    ALTER TABLE "plans" ADD COLUMN "max_dunning_attempts" integer;
    ALTER TABLE "plans" ALTER COLUMN "max_dunning_attempts" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'soft_limit_percentage') THEN
    ALTER TABLE "plans" ADD COLUMN "soft_limit_percentage" integer;
    ALTER TABLE "plans" ALTER COLUMN "soft_limit_percentage" SET DEFAULT 80;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'allow_pausing') THEN
    ALTER TABLE "plans" ADD COLUMN "allow_pausing" boolean;
    ALTER TABLE "plans" ALTER COLUMN "allow_pausing" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'pause_max_days') THEN
    ALTER TABLE "plans" ADD COLUMN "pause_max_days" integer;
    ALTER TABLE "plans" ALTER COLUMN "pause_max_days" SET DEFAULT 90;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'storage_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "storage_limit" integer;
    ALTER TABLE "plans" ALTER COLUMN "storage_limit" SET DEFAULT 1024;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'bandwidth_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "bandwidth_limit" integer;
    ALTER TABLE "plans" ALTER COLUMN "bandwidth_limit" SET DEFAULT 10240;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'file_upload_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "file_upload_limit" integer;
    ALTER TABLE "plans" ALTER COLUMN "file_upload_limit" SET DEFAULT 25;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'total_files_limit') THEN
    ALTER TABLE "plans" ADD COLUMN "total_files_limit" integer;
    ALTER TABLE "plans" ALTER COLUMN "total_files_limit" SET DEFAULT 1000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plans' AND column_name = 'custom_duration_days') THEN
    ALTER TABLE "plans" ADD COLUMN "custom_duration_days" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'id') THEN
    ALTER TABLE "contacts" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'company_id') THEN
    ALTER TABLE "contacts" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'name') THEN
    ALTER TABLE "contacts" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'avatar_url') THEN
    ALTER TABLE "contacts" ADD COLUMN "avatar_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'email') THEN
    ALTER TABLE "contacts" ADD COLUMN "email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'phone') THEN
    ALTER TABLE "contacts" ADD COLUMN "phone" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'company') THEN
    ALTER TABLE "contacts" ADD COLUMN "company" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'tags') THEN
    ALTER TABLE "contacts" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'is_active') THEN
    ALTER TABLE "contacts" ADD COLUMN "is_active" boolean;
    ALTER TABLE "contacts" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'identifier') THEN
    ALTER TABLE "contacts" ADD COLUMN "identifier" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'identifier_type') THEN
    ALTER TABLE "contacts" ADD COLUMN "identifier_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'source') THEN
    ALTER TABLE "contacts" ADD COLUMN "source" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'notes') THEN
    ALTER TABLE "contacts" ADD COLUMN "notes" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'created_at') THEN
    ALTER TABLE "contacts" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "contacts" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'updated_at') THEN
    ALTER TABLE "contacts" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "contacts" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'is_history_sync') THEN
    ALTER TABLE "contacts" ADD COLUMN "is_history_sync" boolean;
    ALTER TABLE "contacts" ALTER COLUMN "is_history_sync" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'history_sync_batch_id') THEN
    ALTER TABLE "contacts" ADD COLUMN "history_sync_batch_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'is_archived') THEN
    ALTER TABLE "contacts" ADD COLUMN "is_archived" boolean;
    ALTER TABLE "contacts" ALTER COLUMN "is_archived" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'assigned_to_user_id') THEN
    ALTER TABLE "contacts" ADD COLUMN "assigned_to_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'id') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'company_id') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'role') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "role" user_role;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'permissions') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "permissions" jsonb;
    ALTER TABLE "role_permissions" ALTER COLUMN "permissions" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'created_at') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "role_permissions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'role_permissions' AND column_name = 'updated_at') THEN
    ALTER TABLE "role_permissions" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "role_permissions" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'id') THEN
    ALTER TABLE "conversations" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'company_id') THEN
    ALTER TABLE "conversations" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'contact_id') THEN
    ALTER TABLE "conversations" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'channel_type') THEN
    ALTER TABLE "conversations" ADD COLUMN "channel_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'channel_id') THEN
    ALTER TABLE "conversations" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'status') THEN
    ALTER TABLE "conversations" ADD COLUMN "status" text;
    ALTER TABLE "conversations" ALTER COLUMN "status" SET DEFAULT 'open'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'assigned_to_user_id') THEN
    ALTER TABLE "conversations" ADD COLUMN "assigned_to_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'last_message_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "last_message_at" timestamp without time zone;
    ALTER TABLE "conversations" ALTER COLUMN "last_message_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'unread_count') THEN
    ALTER TABLE "conversations" ADD COLUMN "unread_count" integer;
    ALTER TABLE "conversations" ALTER COLUMN "unread_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'bot_disabled') THEN
    ALTER TABLE "conversations" ADD COLUMN "bot_disabled" boolean;
    ALTER TABLE "conversations" ALTER COLUMN "bot_disabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'disabled_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "disabled_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'disable_duration') THEN
    ALTER TABLE "conversations" ADD COLUMN "disable_duration" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'disable_reason') THEN
    ALTER TABLE "conversations" ADD COLUMN "disable_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'is_group') THEN
    ALTER TABLE "conversations" ADD COLUMN "is_group" boolean;
    ALTER TABLE "conversations" ALTER COLUMN "is_group" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_jid') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_jid" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_name') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_description') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_participant_count') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_participant_count" integer;
    ALTER TABLE "conversations" ALTER COLUMN "group_participant_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_created_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_created_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'group_metadata') THEN
    ALTER TABLE "conversations" ADD COLUMN "group_metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'created_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "conversations" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'updated_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "conversations" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'is_history_sync') THEN
    ALTER TABLE "conversations" ADD COLUMN "is_history_sync" boolean;
    ALTER TABLE "conversations" ALTER COLUMN "is_history_sync" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'history_sync_batch_id') THEN
    ALTER TABLE "conversations" ADD COLUMN "history_sync_batch_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'is_starred') THEN
    ALTER TABLE "conversations" ADD COLUMN "is_starred" boolean;
    ALTER TABLE "conversations" ALTER COLUMN "is_starred" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'is_archived') THEN
    ALTER TABLE "conversations" ADD COLUMN "is_archived" boolean;
    ALTER TABLE "conversations" ALTER COLUMN "is_archived" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'archived_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "archived_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'starred_at') THEN
    ALTER TABLE "conversations" ADD COLUMN "starred_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'tags') THEN
    ALTER TABLE "conversations" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'id') THEN
    ALTER TABLE "companies" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'name') THEN
    ALTER TABLE "companies" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'slug') THEN
    ALTER TABLE "companies" ADD COLUMN "slug" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subdomain') THEN
    ALTER TABLE "companies" ADD COLUMN "subdomain" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'logo') THEN
    ALTER TABLE "companies" ADD COLUMN "logo" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'primary_color') THEN
    ALTER TABLE "companies" ADD COLUMN "primary_color" text;
    ALTER TABLE "companies" ALTER COLUMN "primary_color" SET DEFAULT '#363636'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'active') THEN
    ALTER TABLE "companies" ADD COLUMN "active" boolean;
    ALTER TABLE "companies" ALTER COLUMN "active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'plan') THEN
    ALTER TABLE "companies" ADD COLUMN "plan" text;
    ALTER TABLE "companies" ALTER COLUMN "plan" SET DEFAULT 'free'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'plan_id') THEN
    ALTER TABLE "companies" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_status') THEN
    ALTER TABLE "companies" ADD COLUMN "subscription_status" text;
    ALTER TABLE "companies" ALTER COLUMN "subscription_status" SET DEFAULT 'inactive'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_start_date') THEN
    ALTER TABLE "companies" ADD COLUMN "subscription_start_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_end_date') THEN
    ALTER TABLE "companies" ADD COLUMN "subscription_end_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'trial_start_date') THEN
    ALTER TABLE "companies" ADD COLUMN "trial_start_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'trial_end_date') THEN
    ALTER TABLE "companies" ADD COLUMN "trial_end_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'is_in_trial') THEN
    ALTER TABLE "companies" ADD COLUMN "is_in_trial" boolean;
    ALTER TABLE "companies" ALTER COLUMN "is_in_trial" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'max_users') THEN
    ALTER TABLE "companies" ADD COLUMN "max_users" integer;
    ALTER TABLE "companies" ALTER COLUMN "max_users" SET DEFAULT 5;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'register_number') THEN
    ALTER TABLE "companies" ADD COLUMN "register_number" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'company_email') THEN
    ALTER TABLE "companies" ADD COLUMN "company_email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'contact_person') THEN
    ALTER TABLE "companies" ADD COLUMN "contact_person" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'iban') THEN
    ALTER TABLE "companies" ADD COLUMN "iban" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'stripe_customer_id') THEN
    ALTER TABLE "companies" ADD COLUMN "stripe_customer_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'stripe_subscription_id') THEN
    ALTER TABLE "companies" ADD COLUMN "stripe_subscription_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'billing_cycle_anchor') THEN
    ALTER TABLE "companies" ADD COLUMN "billing_cycle_anchor" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'grace_period_end') THEN
    ALTER TABLE "companies" ADD COLUMN "grace_period_end" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'pause_start_date') THEN
    ALTER TABLE "companies" ADD COLUMN "pause_start_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'pause_end_date') THEN
    ALTER TABLE "companies" ADD COLUMN "pause_end_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'auto_renewal') THEN
    ALTER TABLE "companies" ADD COLUMN "auto_renewal" boolean;
    ALTER TABLE "companies" ALTER COLUMN "auto_renewal" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'dunning_attempts') THEN
    ALTER TABLE "companies" ADD COLUMN "dunning_attempts" integer;
    ALTER TABLE "companies" ALTER COLUMN "dunning_attempts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'last_dunning_attempt') THEN
    ALTER TABLE "companies" ADD COLUMN "last_dunning_attempt" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_metadata') THEN
    ALTER TABLE "companies" ADD COLUMN "subscription_metadata" jsonb;
    ALTER TABLE "companies" ALTER COLUMN "subscription_metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'current_storage_used') THEN
    ALTER TABLE "companies" ADD COLUMN "current_storage_used" integer;
    ALTER TABLE "companies" ALTER COLUMN "current_storage_used" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'current_bandwidth_used') THEN
    ALTER TABLE "companies" ADD COLUMN "current_bandwidth_used" integer;
    ALTER TABLE "companies" ALTER COLUMN "current_bandwidth_used" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'files_count') THEN
    ALTER TABLE "companies" ADD COLUMN "files_count" integer;
    ALTER TABLE "companies" ALTER COLUMN "files_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'last_usage_update') THEN
    ALTER TABLE "companies" ADD COLUMN "last_usage_update" timestamp without time zone;
    ALTER TABLE "companies" ALTER COLUMN "last_usage_update" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'created_at') THEN
    ALTER TABLE "companies" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "companies" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'updated_at') THEN
    ALTER TABLE "companies" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "companies" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'id') THEN
    ALTER TABLE "users" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'username') THEN
    ALTER TABLE "users" ADD COLUMN "username" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password') THEN
    ALTER TABLE "users" ADD COLUMN "password" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'full_name') THEN
    ALTER TABLE "users" ADD COLUMN "full_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') THEN
    ALTER TABLE "users" ADD COLUMN "email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'avatar_url') THEN
    ALTER TABLE "users" ADD COLUMN "avatar_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
    ALTER TABLE "users" ADD COLUMN "role" user_role;
    ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'agent'::user_role;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'company_id') THEN
    ALTER TABLE "users" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_super_admin') THEN
    ALTER TABLE "users" ADD COLUMN "is_super_admin" boolean;
    ALTER TABLE "users" ALTER COLUMN "is_super_admin" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'active') THEN
    ALTER TABLE "users" ADD COLUMN "active" boolean;
    ALTER TABLE "users" ALTER COLUMN "active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'language_preference') THEN
    ALTER TABLE "users" ADD COLUMN "language_preference" text;
    ALTER TABLE "users" ALTER COLUMN "language_preference" SET DEFAULT 'en'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'permissions') THEN
    ALTER TABLE "users" ADD COLUMN "permissions" jsonb;
    ALTER TABLE "users" ALTER COLUMN "permissions" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_at') THEN
    ALTER TABLE "users" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "users" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'updated_at') THEN
    ALTER TABLE "users" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "users" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'mobile_phone') THEN
    ALTER TABLE "users" ADD COLUMN "mobile_phone" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'notification_preferences') THEN
    ALTER TABLE "users" ADD COLUMN "notification_preferences" jsonb;
    ALTER TABLE "users" ALTER COLUMN "notification_preferences" SET DEFAULT '{"email": true, "whatsapp": false}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'id') THEN
    ALTER TABLE "group_participants" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'conversation_id') THEN
    ALTER TABLE "group_participants" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'contact_id') THEN
    ALTER TABLE "group_participants" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'participant_jid') THEN
    ALTER TABLE "group_participants" ADD COLUMN "participant_jid" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'participant_name') THEN
    ALTER TABLE "group_participants" ADD COLUMN "participant_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'is_admin') THEN
    ALTER TABLE "group_participants" ADD COLUMN "is_admin" boolean;
    ALTER TABLE "group_participants" ALTER COLUMN "is_admin" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'is_super_admin') THEN
    ALTER TABLE "group_participants" ADD COLUMN "is_super_admin" boolean;
    ALTER TABLE "group_participants" ALTER COLUMN "is_super_admin" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'joined_at') THEN
    ALTER TABLE "group_participants" ADD COLUMN "joined_at" timestamp without time zone;
    ALTER TABLE "group_participants" ALTER COLUMN "joined_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'left_at') THEN
    ALTER TABLE "group_participants" ADD COLUMN "left_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'is_active') THEN
    ALTER TABLE "group_participants" ADD COLUMN "is_active" boolean;
    ALTER TABLE "group_participants" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'created_at') THEN
    ALTER TABLE "group_participants" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "group_participants" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'group_participants' AND column_name = 'updated_at') THEN
    ALTER TABLE "group_participants" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "group_participants" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'id') THEN
    ALTER TABLE "notes" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'contact_id') THEN
    ALTER TABLE "notes" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'created_by_id') THEN
    ALTER TABLE "notes" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'content') THEN
    ALTER TABLE "notes" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'created_at') THEN
    ALTER TABLE "notes" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "notes" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'updated_at') THEN
    ALTER TABLE "notes" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "notes" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'id') THEN
    ALTER TABLE "flows" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'user_id') THEN
    ALTER TABLE "flows" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'company_id') THEN
    ALTER TABLE "flows" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'name') THEN
    ALTER TABLE "flows" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'description') THEN
    ALTER TABLE "flows" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'status') THEN
    ALTER TABLE "flows" ADD COLUMN "status" text;
    ALTER TABLE "flows" ALTER COLUMN "status" SET DEFAULT 'draft'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'nodes') THEN
    ALTER TABLE "flows" ADD COLUMN "nodes" jsonb;
    ALTER TABLE "flows" ALTER COLUMN "nodes" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'edges') THEN
    ALTER TABLE "flows" ADD COLUMN "edges" jsonb;
    ALTER TABLE "flows" ALTER COLUMN "edges" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'version') THEN
    ALTER TABLE "flows" ADD COLUMN "version" integer;
    ALTER TABLE "flows" ALTER COLUMN "version" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'created_at') THEN
    ALTER TABLE "flows" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flows" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flows' AND column_name = 'updated_at') THEN
    ALTER TABLE "flows" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flows" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'id') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'flow_id') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'channel_id') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'is_active') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "is_active" boolean;
    ALTER TABLE "flow_assignments" ALTER COLUMN "is_active" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_assignments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_assignments' AND column_name = 'updated_at') THEN
    ALTER TABLE "flow_assignments" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flow_assignments" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'execution_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "execution_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'flow_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'conversation_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'contact_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'company_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'status') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "status" text;
    ALTER TABLE "flow_executions" ALTER COLUMN "status" SET DEFAULT 'running'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'trigger_node_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "trigger_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'current_node_id') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "current_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'execution_path') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "execution_path" jsonb;
    ALTER TABLE "flow_executions" ALTER COLUMN "execution_path" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'context_data') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "context_data" jsonb;
    ALTER TABLE "flow_executions" ALTER COLUMN "context_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'started_at') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "started_at" timestamp without time zone;
    ALTER TABLE "flow_executions" ALTER COLUMN "started_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'completed_at') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'last_activity_at') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "last_activity_at" timestamp without time zone;
    ALTER TABLE "flow_executions" ALTER COLUMN "last_activity_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'total_duration_ms') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "total_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'completion_rate') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "completion_rate" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'error_message') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_executions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_executions' AND column_name = 'updated_at') THEN
    ALTER TABLE "flow_executions" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flow_executions" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'session_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'flow_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'conversation_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'contact_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'company_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'status') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "status" text;
    ALTER TABLE "flow_sessions" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'current_node_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "current_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'trigger_node_id') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "trigger_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'execution_path') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "execution_path" jsonb;
    ALTER TABLE "flow_sessions" ALTER COLUMN "execution_path" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'branching_history') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "branching_history" jsonb;
    ALTER TABLE "flow_sessions" ALTER COLUMN "branching_history" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'session_data') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "session_data" jsonb;
    ALTER TABLE "flow_sessions" ALTER COLUMN "session_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'node_states') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "node_states" jsonb;
    ALTER TABLE "flow_sessions" ALTER COLUMN "node_states" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'waiting_context') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "waiting_context" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'started_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "started_at" timestamp without time zone;
    ALTER TABLE "flow_sessions" ALTER COLUMN "started_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'last_activity_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "last_activity_at" timestamp without time zone;
    ALTER TABLE "flow_sessions" ALTER COLUMN "last_activity_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'paused_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "paused_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'resumed_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "resumed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'completed_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'expires_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'total_duration_ms') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "total_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'node_execution_count') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "node_execution_count" integer;
    ALTER TABLE "flow_sessions" ALTER COLUMN "node_execution_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'user_interaction_count') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "user_interaction_count" integer;
    ALTER TABLE "flow_sessions" ALTER COLUMN "user_interaction_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'error_count') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "error_count" integer;
    ALTER TABLE "flow_sessions" ALTER COLUMN "error_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'last_error_message') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "last_error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'checkpoint_data') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "checkpoint_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'debug_info') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "debug_info" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_sessions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_sessions' AND column_name = 'updated_at') THEN
    ALTER TABLE "flow_sessions" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flow_sessions" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'id') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'session_id') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'variable_key') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "variable_key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'variable_value') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "variable_value" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'variable_type') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "variable_type" text;
    ALTER TABLE "flow_session_variables" ALTER COLUMN "variable_type" SET DEFAULT 'string'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'scope') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "scope" text;
    ALTER TABLE "flow_session_variables" ALTER COLUMN "scope" SET DEFAULT 'session'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'node_id') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'is_encrypted') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "is_encrypted" boolean;
    ALTER TABLE "flow_session_variables" ALTER COLUMN "is_encrypted" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'expires_at') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_session_variables" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_variables' AND column_name = 'updated_at') THEN
    ALTER TABLE "flow_session_variables" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flow_session_variables" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'id') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'flow_execution_id') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "flow_execution_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'node_id') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'node_type') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "node_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'step_order') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "step_order" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'started_at') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "started_at" timestamp without time zone;
    ALTER TABLE "flow_step_executions" ALTER COLUMN "started_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'completed_at') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'duration_ms') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'status') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "status" text;
    ALTER TABLE "flow_step_executions" ALTER COLUMN "status" SET DEFAULT 'running'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'input_data') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "input_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'output_data') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "output_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'error_message') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_step_executions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'session_id') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'retry_count') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "retry_count" integer;
    ALTER TABLE "flow_step_executions" ALTER COLUMN "retry_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_step_executions' AND column_name = 'max_retries') THEN
    ALTER TABLE "flow_step_executions" ADD COLUMN "max_retries" integer;
    ALTER TABLE "flow_step_executions" ALTER COLUMN "max_retries" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'id') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'session_id') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'current_node_id') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "current_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'previous_node_id') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "previous_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'next_possible_nodes') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "next_possible_nodes" jsonb;
    ALTER TABLE "flow_session_cursors" ALTER COLUMN "next_possible_nodes" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'branch_conditions') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "branch_conditions" jsonb;
    ALTER TABLE "flow_session_cursors" ALTER COLUMN "branch_conditions" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'loop_state') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "loop_state" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'waiting_for_input') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "waiting_for_input" boolean;
    ALTER TABLE "flow_session_cursors" ALTER COLUMN "waiting_for_input" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'input_expected_type') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "input_expected_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'input_validation_rules') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "input_validation_rules" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'timeout_at') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "timeout_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'created_at') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "flow_session_cursors" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flow_session_cursors' AND column_name = 'updated_at') THEN
    ALTER TABLE "flow_session_cursors" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "flow_session_cursors" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'id') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'company_id') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'name') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'description') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'message_type') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "message_type" text;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "message_type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'content') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'media_url') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "media_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'caption') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "caption" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'default_delay_amount') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "default_delay_amount" integer;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "default_delay_amount" SET DEFAULT 24;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'default_delay_unit') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "default_delay_unit" text;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "default_delay_unit" SET DEFAULT 'hours'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'variables') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "variables" jsonb;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "variables" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'category') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "category" text;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "category" SET DEFAULT 'general'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'is_active') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "is_active" boolean;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'usage_count') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "usage_count" integer;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "usage_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'created_by') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'created_at') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_templates' AND column_name = 'updated_at') THEN
    ALTER TABLE "follow_up_templates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "follow_up_templates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'id') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'email') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'invited_by_user_id') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "invited_by_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'company_id') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'role') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "role" text;
    ALTER TABLE "team_invitations" ALTER COLUMN "role" SET DEFAULT 'agent'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'token') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'status') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "status" text;
    ALTER TABLE "team_invitations" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'expires_at') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'created_at') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "team_invitations" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'team_invitations' AND column_name = 'updated_at') THEN
    ALTER TABLE "team_invitations" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "team_invitations" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'id') THEN
    ALTER TABLE "deals" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'company_id') THEN
    ALTER TABLE "deals" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'contact_id') THEN
    ALTER TABLE "deals" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'title') THEN
    ALTER TABLE "deals" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'stage_id') THEN
    ALTER TABLE "deals" ADD COLUMN "stage_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'stage') THEN
    ALTER TABLE "deals" ADD COLUMN "stage" text;
    ALTER TABLE "deals" ALTER COLUMN "stage" SET DEFAULT 'lead'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'value') THEN
    ALTER TABLE "deals" ADD COLUMN "value" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'priority') THEN
    ALTER TABLE "deals" ADD COLUMN "priority" text;
    ALTER TABLE "deals" ALTER COLUMN "priority" SET DEFAULT 'medium'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'due_date') THEN
    ALTER TABLE "deals" ADD COLUMN "due_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'assigned_to_user_id') THEN
    ALTER TABLE "deals" ADD COLUMN "assigned_to_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'description') THEN
    ALTER TABLE "deals" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'tags') THEN
    ALTER TABLE "deals" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'status') THEN
    ALTER TABLE "deals" ADD COLUMN "status" text;
    ALTER TABLE "deals" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'last_activity_at') THEN
    ALTER TABLE "deals" ADD COLUMN "last_activity_at" timestamp without time zone;
    ALTER TABLE "deals" ALTER COLUMN "last_activity_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'created_at') THEN
    ALTER TABLE "deals" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deals" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'updated_at') THEN
    ALTER TABLE "deals" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "deals" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'id') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'deal_id') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "deal_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'user_id') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'type') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'content') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'metadata') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_activities' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_activities" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_activities" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'id') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'user_id') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'company_id') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'access_token') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'refresh_token') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "refresh_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'id_token') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "id_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'token_type') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "token_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'expiry_date') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "expiry_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'scope') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "scope" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'created_at') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "google_calendar_tokens" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'google_calendar_tokens' AND column_name = 'updated_at') THEN
    ALTER TABLE "google_calendar_tokens" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "google_calendar_tokens" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'id') THEN
    ALTER TABLE "app_settings" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'key') THEN
    ALTER TABLE "app_settings" ADD COLUMN "key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'value') THEN
    ALTER TABLE "app_settings" ADD COLUMN "value" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'created_at') THEN
    ALTER TABLE "app_settings" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "app_settings" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'updated_at') THEN
    ALTER TABLE "app_settings" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "app_settings" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'id') THEN
    ALTER TABLE "company_settings" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'company_id') THEN
    ALTER TABLE "company_settings" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'key') THEN
    ALTER TABLE "company_settings" ADD COLUMN "key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'value') THEN
    ALTER TABLE "company_settings" ADD COLUMN "value" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'created_at') THEN
    ALTER TABLE "company_settings" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "company_settings" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_settings' AND column_name = 'updated_at') THEN
    ALTER TABLE "company_settings" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "company_settings" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'id') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'company_id') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'name') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'color') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "color" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'order_num') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "order_num" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'created_at') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "pipeline_stages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'updated_at') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "pipeline_stages" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipeline_stages' AND column_name = 'pipeline_id') THEN
    ALTER TABLE "pipeline_stages" ADD COLUMN "pipeline_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'company_id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'plan_id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'amount') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'currency') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "currency" text;
    ALTER TABLE "payment_transactions" ALTER COLUMN "currency" SET DEFAULT 'USD'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'status') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "status" text;
    ALTER TABLE "payment_transactions" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'payment_method') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "payment_method" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'payment_intent_id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "payment_intent_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'external_transaction_id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "external_transaction_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'receipt_url') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "receipt_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'metadata') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'created_at') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "payment_transactions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'updated_at') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "payment_transactions" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'original_amount') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "original_amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'discount_amount') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "discount_amount" numeric;
    ALTER TABLE "payment_transactions" ALTER COLUMN "discount_amount" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'coupon_code_id') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "coupon_code_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'affiliate_credit_applied') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "affiliate_credit_applied" numeric;
    ALTER TABLE "payment_transactions" ALTER COLUMN "affiliate_credit_applied" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'discount_details') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "discount_details" jsonb;
    ALTER TABLE "payment_transactions" ALTER COLUMN "discount_details" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'is_recurring') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "is_recurring" boolean;
    ALTER TABLE "payment_transactions" ALTER COLUMN "is_recurring" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'subscription_period_start') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "subscription_period_start" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'subscription_period_end') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "subscription_period_end" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'proration_amount') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "proration_amount" numeric;
    ALTER TABLE "payment_transactions" ALTER COLUMN "proration_amount" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_transactions' AND column_name = 'dunning_attempt') THEN
    ALTER TABLE "payment_transactions" ADD COLUMN "dunning_attempt" integer;
    ALTER TABLE "payment_transactions" ALTER COLUMN "dunning_attempt" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'id') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'user_id') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'token') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "token" VARCHAR(255);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'expires_at') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'used_at') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "used_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'created_at') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "password_reset_tokens" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'ip_address') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "ip_address" inet;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'password_reset_tokens' AND column_name = 'user_agent') THEN
    ALTER TABLE "password_reset_tokens" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_namespaces' AND column_name = 'id') THEN
    ALTER TABLE "translation_namespaces" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_namespaces' AND column_name = 'name') THEN
    ALTER TABLE "translation_namespaces" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_namespaces' AND column_name = 'description') THEN
    ALTER TABLE "translation_namespaces" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_namespaces' AND column_name = 'created_at') THEN
    ALTER TABLE "translation_namespaces" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "translation_namespaces" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_namespaces' AND column_name = 'updated_at') THEN
    ALTER TABLE "translation_namespaces" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "translation_namespaces" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'id') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'namespace_id') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "namespace_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'key') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'description') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'created_at') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "translation_keys" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translation_keys' AND column_name = 'updated_at') THEN
    ALTER TABLE "translation_keys" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "translation_keys" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'id') THEN
    ALTER TABLE "translations" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'key_id') THEN
    ALTER TABLE "translations" ADD COLUMN "key_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'language_id') THEN
    ALTER TABLE "translations" ADD COLUMN "language_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'value') THEN
    ALTER TABLE "translations" ADD COLUMN "value" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'created_at') THEN
    ALTER TABLE "translations" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "translations" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'translations' AND column_name = 'updated_at') THEN
    ALTER TABLE "translations" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "translations" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'id') THEN
    ALTER TABLE "languages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'code') THEN
    ALTER TABLE "languages" ADD COLUMN "code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'name') THEN
    ALTER TABLE "languages" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'native_name') THEN
    ALTER TABLE "languages" ADD COLUMN "native_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'flag_icon') THEN
    ALTER TABLE "languages" ADD COLUMN "flag_icon" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'is_active') THEN
    ALTER TABLE "languages" ADD COLUMN "is_active" boolean;
    ALTER TABLE "languages" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'is_default') THEN
    ALTER TABLE "languages" ADD COLUMN "is_default" boolean;
    ALTER TABLE "languages" ALTER COLUMN "is_default" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'direction') THEN
    ALTER TABLE "languages" ADD COLUMN "direction" text;
    ALTER TABLE "languages" ALTER COLUMN "direction" SET DEFAULT 'ltr'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'created_at') THEN
    ALTER TABLE "languages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "languages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'languages' AND column_name = 'updated_at') THEN
    ALTER TABLE "languages" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "languages" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'session' AND column_name = 'sid') THEN
    ALTER TABLE "session" ADD COLUMN "sid" VARCHAR(255);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'session' AND column_name = 'sess') THEN
    ALTER TABLE "session" ADD COLUMN "sess" json;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'session' AND column_name = 'expire') THEN
    ALTER TABLE "session" ADD COLUMN "expire" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'id') THEN
    ALTER TABLE "system_updates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'version') THEN
    ALTER TABLE "system_updates" ADD COLUMN "version" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'release_notes') THEN
    ALTER TABLE "system_updates" ADD COLUMN "release_notes" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'download_url') THEN
    ALTER TABLE "system_updates" ADD COLUMN "download_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'package_hash') THEN
    ALTER TABLE "system_updates" ADD COLUMN "package_hash" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'package_size') THEN
    ALTER TABLE "system_updates" ADD COLUMN "package_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'status') THEN
    ALTER TABLE "system_updates" ADD COLUMN "status" update_status;
    ALTER TABLE "system_updates" ALTER COLUMN "status" SET DEFAULT 'pending'::update_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'scheduled_at') THEN
    ALTER TABLE "system_updates" ADD COLUMN "scheduled_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'started_at') THEN
    ALTER TABLE "system_updates" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'completed_at') THEN
    ALTER TABLE "system_updates" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'error_message') THEN
    ALTER TABLE "system_updates" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'rollback_data') THEN
    ALTER TABLE "system_updates" ADD COLUMN "rollback_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'migration_scripts') THEN
    ALTER TABLE "system_updates" ADD COLUMN "migration_scripts" jsonb;
    ALTER TABLE "system_updates" ALTER COLUMN "migration_scripts" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'backup_path') THEN
    ALTER TABLE "system_updates" ADD COLUMN "backup_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'progress_percentage') THEN
    ALTER TABLE "system_updates" ADD COLUMN "progress_percentage" integer;
    ALTER TABLE "system_updates" ALTER COLUMN "progress_percentage" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'created_at') THEN
    ALTER TABLE "system_updates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "system_updates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_updates' AND column_name = 'updated_at') THEN
    ALTER TABLE "system_updates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "system_updates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'id') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'company_id') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'created_by_id') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'name') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'description') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'criteria') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "criteria" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'contact_count') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "contact_count" integer;
    ALTER TABLE "contact_segments" ALTER COLUMN "contact_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'last_updated_at') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "last_updated_at" timestamp without time zone;
    ALTER TABLE "contact_segments" ALTER COLUMN "last_updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'created_at') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "contact_segments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_segments' AND column_name = 'updated_at') THEN
    ALTER TABLE "contact_segments" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "contact_segments" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'id') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'log_id') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "log_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'schedule_id') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "schedule_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'backup_id') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "backup_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'status') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'timestamp') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "timestamp" timestamp without time zone;
    ALTER TABLE "backup_logs" ALTER COLUMN "timestamp" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'error_message') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_logs' AND column_name = 'metadata') THEN
    ALTER TABLE "backup_logs" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'id') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'company_id') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'created_by_id') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'name') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'description') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'category') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "category" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "category" SET DEFAULT 'general'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'content') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'content_type') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "content_type" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "content_type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'media_urls') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "media_urls" jsonb;
    ALTER TABLE "campaign_templates" ALTER COLUMN "media_urls" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'media_metadata') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "media_metadata" jsonb;
    ALTER TABLE "campaign_templates" ALTER COLUMN "media_metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'variables') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "variables" jsonb;
    ALTER TABLE "campaign_templates" ALTER COLUMN "variables" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'channel_type') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "channel_type" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "channel_type" SET DEFAULT 'whatsapp'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'is_active') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "is_active" boolean;
    ALTER TABLE "campaign_templates" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'usage_count') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "usage_count" integer;
    ALTER TABLE "campaign_templates" ALTER COLUMN "usage_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'created_at') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "campaign_templates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'updated_at') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "campaign_templates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_channel_type') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_channel_type" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "whatsapp_channel_type" SET DEFAULT 'unofficial'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_template_category') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_template_category" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_template_status') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_template_status" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "whatsapp_template_status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_template_id') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_template_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_template_name') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_template_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'whatsapp_template_language') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "whatsapp_template_language" text;
    ALTER TABLE "campaign_templates" ALTER COLUMN "whatsapp_template_language" SET DEFAULT 'en'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'connection_id') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "connection_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_templates' AND column_name = 'media_handle') THEN
    ALTER TABLE "campaign_templates" ADD COLUMN "media_handle" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'company_id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'created_by_id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'template_id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "template_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'segment_id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "segment_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'name') THEN
    ALTER TABLE "campaigns" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'description') THEN
    ALTER TABLE "campaigns" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'channel_type') THEN
    ALTER TABLE "campaigns" ADD COLUMN "channel_type" text;
    ALTER TABLE "campaigns" ALTER COLUMN "channel_type" SET DEFAULT 'whatsapp'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'channel_id') THEN
    ALTER TABLE "campaigns" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'channel_ids') THEN
    ALTER TABLE "campaigns" ADD COLUMN "channel_ids" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "channel_ids" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'content') THEN
    ALTER TABLE "campaigns" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'media_urls') THEN
    ALTER TABLE "campaigns" ADD COLUMN "media_urls" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "media_urls" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'variables') THEN
    ALTER TABLE "campaigns" ADD COLUMN "variables" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "variables" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'campaign_type') THEN
    ALTER TABLE "campaigns" ADD COLUMN "campaign_type" text;
    ALTER TABLE "campaigns" ALTER COLUMN "campaign_type" SET DEFAULT 'immediate'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'scheduled_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "scheduled_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'timezone') THEN
    ALTER TABLE "campaigns" ADD COLUMN "timezone" text;
    ALTER TABLE "campaigns" ALTER COLUMN "timezone" SET DEFAULT 'UTC'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'drip_settings') THEN
    ALTER TABLE "campaigns" ADD COLUMN "drip_settings" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'status') THEN
    ALTER TABLE "campaigns" ADD COLUMN "status" text;
    ALTER TABLE "campaigns" ALTER COLUMN "status" SET DEFAULT 'draft'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'started_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'completed_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'paused_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "paused_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'total_recipients') THEN
    ALTER TABLE "campaigns" ADD COLUMN "total_recipients" integer;
    ALTER TABLE "campaigns" ALTER COLUMN "total_recipients" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'processed_recipients') THEN
    ALTER TABLE "campaigns" ADD COLUMN "processed_recipients" integer;
    ALTER TABLE "campaigns" ALTER COLUMN "processed_recipients" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'successful_sends') THEN
    ALTER TABLE "campaigns" ADD COLUMN "successful_sends" integer;
    ALTER TABLE "campaigns" ALTER COLUMN "successful_sends" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'failed_sends') THEN
    ALTER TABLE "campaigns" ADD COLUMN "failed_sends" integer;
    ALTER TABLE "campaigns" ALTER COLUMN "failed_sends" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'rate_limit_settings') THEN
    ALTER TABLE "campaigns" ADD COLUMN "rate_limit_settings" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "rate_limit_settings" SET DEFAULT '{"messages_per_day": 1000, "messages_per_hour": 200, "random_delay_range": [3, 10], "messages_per_minute": 10, "humanization_enabled": true, "delay_between_messages": 6}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'compliance_settings') THEN
    ALTER TABLE "campaigns" ADD COLUMN "compliance_settings" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "compliance_settings" SET DEFAULT '{"require_opt_out": true, "spam_check_enabled": true, "content_filter_enabled": true}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'anti_ban_settings') THEN
    ALTER TABLE "campaigns" ADD COLUMN "anti_ban_settings" jsonb;
    ALTER TABLE "campaigns" ALTER COLUMN "anti_ban_settings" SET DEFAULT '{"mode": "moderate", "enabled": true, "maxDelay": 15, "minDelay": 3, "cooldownPeriod": 30, "randomizeDelay": true, "accountRotation": true, "respectWeekends": false, "messageVariation": false, "businessHoursOnly": false}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'created_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "campaigns" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'updated_at') THEN
    ALTER TABLE "campaigns" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "campaigns" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaigns' AND column_name = 'whatsapp_channel_type') THEN
    ALTER TABLE "campaigns" ADD COLUMN "whatsapp_channel_type" text;
    ALTER TABLE "campaigns" ALTER COLUMN "whatsapp_channel_type" SET DEFAULT 'unofficial'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'id') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'campaign_id') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "campaign_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'contact_id') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'personalized_content') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "personalized_content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'variables') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "variables" jsonb;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "variables" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'status') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "status" text;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'scheduled_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "scheduled_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'sent_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'delivered_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "delivered_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'read_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "read_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'failed_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "failed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'error_message') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'retry_count') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "retry_count" integer;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "retry_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'max_retries') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "max_retries" integer;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "max_retries" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'external_message_id') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "external_message_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'conversation_id') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'created_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_recipients' AND column_name = 'updated_at') THEN
    ALTER TABLE "campaign_recipients" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "campaign_recipients" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'id') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'campaign_id') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "campaign_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'recipient_id') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "recipient_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'message_id') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "message_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'content') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'media_urls') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "media_urls" jsonb;
    ALTER TABLE "campaign_messages" ALTER COLUMN "media_urls" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'message_type') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "message_type" text;
    ALTER TABLE "campaign_messages" ALTER COLUMN "message_type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'status') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "status" text;
    ALTER TABLE "campaign_messages" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'sent_at') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'delivered_at') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "delivered_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'read_at') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "read_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'failed_at') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "failed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'whatsapp_message_id') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "whatsapp_message_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'whatsapp_status') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "whatsapp_status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'error_code') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "error_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'error_message') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_messages' AND column_name = 'created_at') THEN
    ALTER TABLE "campaign_messages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "campaign_messages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'id') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'campaign_id') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "campaign_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'recorded_at') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "recorded_at" timestamp without time zone;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "recorded_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'total_recipients') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "total_recipients" integer;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "total_recipients" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'messages_sent') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "messages_sent" integer;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "messages_sent" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'messages_delivered') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "messages_delivered" integer;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "messages_delivered" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'messages_read') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "messages_read" integer;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "messages_read" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'messages_failed') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "messages_failed" integer;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "messages_failed" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'delivery_rate') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "delivery_rate" numeric;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "delivery_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'read_rate') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "read_rate" numeric;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "read_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'failure_rate') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "failure_rate" numeric;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "failure_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'avg_delivery_time') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "avg_delivery_time" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'avg_read_time') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "avg_read_time" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'estimated_cost') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "estimated_cost" numeric;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "estimated_cost" SET DEFAULT 0.0000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_analytics' AND column_name = 'metrics_data') THEN
    ALTER TABLE "campaign_analytics" ADD COLUMN "metrics_data" jsonb;
    ALTER TABLE "campaign_analytics" ALTER COLUMN "metrics_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'id') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'company_id') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'channel_id') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'account_name') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "account_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'phone_number') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "phone_number" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'account_type') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "account_type" text;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "account_type" SET DEFAULT 'unofficial'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'session_data') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "session_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'qr_code') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "qr_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'connection_status') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "connection_status" text;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "connection_status" SET DEFAULT 'disconnected'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'last_activity_at') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "last_activity_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'message_count_today') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "message_count_today" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "message_count_today" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'message_count_hour') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "message_count_hour" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "message_count_hour" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'warning_count') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "warning_count" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "warning_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'restriction_count') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "restriction_count" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "restriction_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'rate_limits') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "rate_limits" jsonb;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "rate_limits" SET DEFAULT '{"cooldown_period": 300, "humanization_enabled": true, "max_messages_per_day": 1000, "max_messages_per_hour": 200, "max_messages_per_minute": 10}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'health_score') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "health_score" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "health_score" SET DEFAULT 100;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'last_health_check') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "last_health_check" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'is_active') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "is_active" boolean;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'rotation_group') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "rotation_group" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'priority') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "priority" integer;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "priority" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'created_at') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_accounts' AND column_name = 'updated_at') THEN
    ALTER TABLE "whatsapp_accounts" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "whatsapp_accounts" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'id') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'account_id') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "account_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'event_type') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "event_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'event_data') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "event_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'message') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'severity') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "severity" text;
    ALTER TABLE "whatsapp_account_logs" ALTER COLUMN "severity" SET DEFAULT 'info'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'messages_sent_today') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "messages_sent_today" integer;
    ALTER TABLE "whatsapp_account_logs" ALTER COLUMN "messages_sent_today" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'health_score') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "health_score" integer;
    ALTER TABLE "whatsapp_account_logs" ALTER COLUMN "health_score" SET DEFAULT 100;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_account_logs' AND column_name = 'created_at') THEN
    ALTER TABLE "whatsapp_account_logs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "whatsapp_account_logs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'id') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'campaign_id') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "campaign_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'recipient_id') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "recipient_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'account_id') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "account_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'priority') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "priority" integer;
    ALTER TABLE "campaign_queue" ALTER COLUMN "priority" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'scheduled_for') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "scheduled_for" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'attempts') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "attempts" integer;
    ALTER TABLE "campaign_queue" ALTER COLUMN "attempts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'max_attempts') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "max_attempts" integer;
    ALTER TABLE "campaign_queue" ALTER COLUMN "max_attempts" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'status') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "status" text;
    ALTER TABLE "campaign_queue" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'started_at') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'completed_at') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'error_message') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'last_error_at') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "last_error_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'metadata') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "campaign_queue" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'created_at') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "campaign_queue" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'campaign_queue' AND column_name = 'updated_at') THEN
    ALTER TABLE "campaign_queue" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "campaign_queue" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'id') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'schedule_id') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "schedule_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'execution_attempt') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "execution_attempt" integer;
    ALTER TABLE "follow_up_execution_log" ALTER COLUMN "execution_attempt" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'status') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'message_id') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "message_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'error_message') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'execution_duration_ms') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "execution_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'executed_at') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "executed_at" timestamp without time zone;
    ALTER TABLE "follow_up_execution_log" ALTER COLUMN "executed_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'response_received') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "response_received" boolean;
    ALTER TABLE "follow_up_execution_log" ALTER COLUMN "response_received" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'response_at') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "response_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_execution_log' AND column_name = 'response_content') THEN
    ALTER TABLE "follow_up_execution_log" ADD COLUMN "response_content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'migration_log' AND column_name = 'id') THEN
    ALTER TABLE "migration_log" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'migration_log' AND column_name = 'migration_name') THEN
    ALTER TABLE "migration_log" ADD COLUMN "migration_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'migration_log' AND column_name = 'executed_at') THEN
    ALTER TABLE "migration_log" ADD COLUMN "executed_at" timestamp without time zone;
    ALTER TABLE "migration_log" ALTER COLUMN "executed_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'migration_log' AND column_name = 'description') THEN
    ALTER TABLE "migration_log" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'id') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'company_id') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'client_id') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "client_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'client_name') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "client_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'status') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "status" text;
    ALTER TABLE "dialog_360_clients" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'onboarded_at') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "onboarded_at" timestamp without time zone;
    ALTER TABLE "dialog_360_clients" ALTER COLUMN "onboarded_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'created_at') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "dialog_360_clients" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_clients' AND column_name = 'updated_at') THEN
    ALTER TABLE "dialog_360_clients" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "dialog_360_clients" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'id') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'company_id') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'business_account_id') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "business_account_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'business_account_name') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "business_account_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'status') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "status" text;
    ALTER TABLE "meta_whatsapp_clients" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'onboarded_at') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "onboarded_at" timestamp without time zone;
    ALTER TABLE "meta_whatsapp_clients" ALTER COLUMN "onboarded_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'created_at') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "meta_whatsapp_clients" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_clients' AND column_name = 'updated_at') THEN
    ALTER TABLE "meta_whatsapp_clients" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "meta_whatsapp_clients" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'id') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'client_id') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "client_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'channel_id') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "channel_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'phone_number') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "phone_number" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'display_name') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "display_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'status') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "status" text;
    ALTER TABLE "dialog_360_channels" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'api_key') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "api_key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'webhook_url') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "webhook_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'quality_rating') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "quality_rating" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'messaging_limit') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "messaging_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'created_at') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "dialog_360_channels" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dialog_360_channels' AND column_name = 'updated_at') THEN
    ALTER TABLE "dialog_360_channels" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "dialog_360_channels" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'id') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'provider') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "provider" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'partner_api_key') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "partner_api_key" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'partner_secret') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "partner_secret" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'partner_id') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "partner_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'webhook_verify_token') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "webhook_verify_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'access_token') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'partner_webhook_url') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "partner_webhook_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'redirect_url') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "redirect_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'public_profile') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "public_profile" jsonb;
    ALTER TABLE "partner_configurations" ALTER COLUMN "public_profile" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'is_active') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "is_active" boolean;
    ALTER TABLE "partner_configurations" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'created_at') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "partner_configurations" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'updated_at') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "partner_configurations" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_configurations' AND column_name = 'config_id') THEN
    ALTER TABLE "partner_configurations" ADD COLUMN "config_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'id') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'client_id') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "client_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'phone_number_id') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "phone_number_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'phone_number') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "phone_number" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'display_name') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "display_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'status') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "status" text;
    ALTER TABLE "meta_whatsapp_phone_numbers" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'quality_rating') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "quality_rating" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'messaging_limit') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "messaging_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'access_token') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'created_at') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "meta_whatsapp_phone_numbers" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meta_whatsapp_phone_numbers' AND column_name = 'updated_at') THEN
    ALTER TABLE "meta_whatsapp_phone_numbers" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "meta_whatsapp_phone_numbers" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'id') THEN
    ALTER TABLE "api_keys" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'company_id') THEN
    ALTER TABLE "api_keys" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'user_id') THEN
    ALTER TABLE "api_keys" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'name') THEN
    ALTER TABLE "api_keys" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'key_hash') THEN
    ALTER TABLE "api_keys" ADD COLUMN "key_hash" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'key_prefix') THEN
    ALTER TABLE "api_keys" ADD COLUMN "key_prefix" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'permissions') THEN
    ALTER TABLE "api_keys" ADD COLUMN "permissions" jsonb;
    ALTER TABLE "api_keys" ALTER COLUMN "permissions" SET DEFAULT '["messages:send", "channels:read"]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'is_active') THEN
    ALTER TABLE "api_keys" ADD COLUMN "is_active" boolean;
    ALTER TABLE "api_keys" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'last_used_at') THEN
    ALTER TABLE "api_keys" ADD COLUMN "last_used_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'expires_at') THEN
    ALTER TABLE "api_keys" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'rate_limit_per_minute') THEN
    ALTER TABLE "api_keys" ADD COLUMN "rate_limit_per_minute" integer;
    ALTER TABLE "api_keys" ALTER COLUMN "rate_limit_per_minute" SET DEFAULT 60;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'rate_limit_per_hour') THEN
    ALTER TABLE "api_keys" ADD COLUMN "rate_limit_per_hour" integer;
    ALTER TABLE "api_keys" ALTER COLUMN "rate_limit_per_hour" SET DEFAULT 1000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'rate_limit_per_day') THEN
    ALTER TABLE "api_keys" ADD COLUMN "rate_limit_per_day" integer;
    ALTER TABLE "api_keys" ALTER COLUMN "rate_limit_per_day" SET DEFAULT 10000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'allowed_ips') THEN
    ALTER TABLE "api_keys" ADD COLUMN "allowed_ips" jsonb;
    ALTER TABLE "api_keys" ALTER COLUMN "allowed_ips" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'webhook_url') THEN
    ALTER TABLE "api_keys" ADD COLUMN "webhook_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'metadata') THEN
    ALTER TABLE "api_keys" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "api_keys" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'created_at') THEN
    ALTER TABLE "api_keys" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "api_keys" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'updated_at') THEN
    ALTER TABLE "api_keys" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "api_keys" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'id') THEN
    ALTER TABLE "api_usage" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'api_key_id') THEN
    ALTER TABLE "api_usage" ADD COLUMN "api_key_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'company_id') THEN
    ALTER TABLE "api_usage" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'endpoint') THEN
    ALTER TABLE "api_usage" ADD COLUMN "endpoint" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'method') THEN
    ALTER TABLE "api_usage" ADD COLUMN "method" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'status_code') THEN
    ALTER TABLE "api_usage" ADD COLUMN "status_code" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'request_size') THEN
    ALTER TABLE "api_usage" ADD COLUMN "request_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'response_size') THEN
    ALTER TABLE "api_usage" ADD COLUMN "response_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'duration') THEN
    ALTER TABLE "api_usage" ADD COLUMN "duration" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'ip_address') THEN
    ALTER TABLE "api_usage" ADD COLUMN "ip_address" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'user_agent') THEN
    ALTER TABLE "api_usage" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'request_id') THEN
    ALTER TABLE "api_usage" ADD COLUMN "request_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'error_message') THEN
    ALTER TABLE "api_usage" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'metadata') THEN
    ALTER TABLE "api_usage" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "api_usage" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_usage' AND column_name = 'created_at') THEN
    ALTER TABLE "api_usage" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "api_usage" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'id') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'api_key_id') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "api_key_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'window_type') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "window_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'window_start') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "window_start" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'request_count') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "request_count" integer;
    ALTER TABLE "api_rate_limits" ALTER COLUMN "request_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'created_at') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "api_rate_limits" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_rate_limits' AND column_name = 'updated_at') THEN
    ALTER TABLE "api_rate_limits" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "api_rate_limits" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'id') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'message_id') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "message_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'filename') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'content_type') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "content_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'size') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'content_id') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "content_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'is_inline') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "is_inline" boolean;
    ALTER TABLE "email_attachments" ALTER COLUMN "is_inline" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'file_path') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "file_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'download_url') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "download_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_attachments' AND column_name = 'created_at') THEN
    ALTER TABLE "email_attachments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "email_attachments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'id') THEN
    ALTER TABLE "email_configs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'channel_connection_id') THEN
    ALTER TABLE "email_configs" ADD COLUMN "channel_connection_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'imap_host') THEN
    ALTER TABLE "email_configs" ADD COLUMN "imap_host" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'imap_port') THEN
    ALTER TABLE "email_configs" ADD COLUMN "imap_port" integer;
    ALTER TABLE "email_configs" ALTER COLUMN "imap_port" SET DEFAULT 993;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'imap_secure') THEN
    ALTER TABLE "email_configs" ADD COLUMN "imap_secure" boolean;
    ALTER TABLE "email_configs" ALTER COLUMN "imap_secure" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'imap_username') THEN
    ALTER TABLE "email_configs" ADD COLUMN "imap_username" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'imap_password') THEN
    ALTER TABLE "email_configs" ADD COLUMN "imap_password" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'smtp_host') THEN
    ALTER TABLE "email_configs" ADD COLUMN "smtp_host" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'smtp_port') THEN
    ALTER TABLE "email_configs" ADD COLUMN "smtp_port" integer;
    ALTER TABLE "email_configs" ALTER COLUMN "smtp_port" SET DEFAULT 465;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'smtp_secure') THEN
    ALTER TABLE "email_configs" ADD COLUMN "smtp_secure" boolean;
    ALTER TABLE "email_configs" ALTER COLUMN "smtp_secure" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'smtp_username') THEN
    ALTER TABLE "email_configs" ADD COLUMN "smtp_username" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'smtp_password') THEN
    ALTER TABLE "email_configs" ADD COLUMN "smtp_password" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_provider') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_provider" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_client_id') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_client_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_client_secret') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_client_secret" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_refresh_token') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_refresh_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_access_token') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'oauth_token_expiry') THEN
    ALTER TABLE "email_configs" ADD COLUMN "oauth_token_expiry" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'email_address') THEN
    ALTER TABLE "email_configs" ADD COLUMN "email_address" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'display_name') THEN
    ALTER TABLE "email_configs" ADD COLUMN "display_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'signature') THEN
    ALTER TABLE "email_configs" ADD COLUMN "signature" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'sync_folder') THEN
    ALTER TABLE "email_configs" ADD COLUMN "sync_folder" text;
    ALTER TABLE "email_configs" ALTER COLUMN "sync_folder" SET DEFAULT 'INBOX'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'sync_frequency') THEN
    ALTER TABLE "email_configs" ADD COLUMN "sync_frequency" integer;
    ALTER TABLE "email_configs" ALTER COLUMN "sync_frequency" SET DEFAULT 60;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'max_sync_messages') THEN
    ALTER TABLE "email_configs" ADD COLUMN "max_sync_messages" integer;
    ALTER TABLE "email_configs" ALTER COLUMN "max_sync_messages" SET DEFAULT 100;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'status') THEN
    ALTER TABLE "email_configs" ADD COLUMN "status" text;
    ALTER TABLE "email_configs" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'last_sync_at') THEN
    ALTER TABLE "email_configs" ADD COLUMN "last_sync_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'last_error') THEN
    ALTER TABLE "email_configs" ADD COLUMN "last_error" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'connection_data') THEN
    ALTER TABLE "email_configs" ADD COLUMN "connection_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'created_at') THEN
    ALTER TABLE "email_configs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "email_configs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'email_configs' AND column_name = 'updated_at') THEN
    ALTER TABLE "email_configs" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "email_configs" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'id') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'user_id') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider_user_id') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider_user_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider_email') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider_email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider_name') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider_avatar_url') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider_avatar_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'access_token') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'refresh_token') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "refresh_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'token_expires_at') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "token_expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'provider_data') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "provider_data" jsonb;
    ALTER TABLE "user_social_accounts" ALTER COLUMN "provider_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'created_at') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "user_social_accounts" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_social_accounts' AND column_name = 'updated_at') THEN
    ALTER TABLE "user_social_accounts" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "user_social_accounts" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'id') THEN
    ALTER TABLE "affiliates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliates" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'user_id') THEN
    ALTER TABLE "affiliates" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'affiliate_code') THEN
    ALTER TABLE "affiliates" ADD COLUMN "affiliate_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'name') THEN
    ALTER TABLE "affiliates" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'email') THEN
    ALTER TABLE "affiliates" ADD COLUMN "email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'phone') THEN
    ALTER TABLE "affiliates" ADD COLUMN "phone" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'website') THEN
    ALTER TABLE "affiliates" ADD COLUMN "website" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'status') THEN
    ALTER TABLE "affiliates" ADD COLUMN "status" affiliate_status;
    ALTER TABLE "affiliates" ALTER COLUMN "status" SET DEFAULT 'pending'::affiliate_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'approved_by') THEN
    ALTER TABLE "affiliates" ADD COLUMN "approved_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'approved_at') THEN
    ALTER TABLE "affiliates" ADD COLUMN "approved_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'rejection_reason') THEN
    ALTER TABLE "affiliates" ADD COLUMN "rejection_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'default_commission_rate') THEN
    ALTER TABLE "affiliates" ADD COLUMN "default_commission_rate" numeric;
    ALTER TABLE "affiliates" ALTER COLUMN "default_commission_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'commission_type') THEN
    ALTER TABLE "affiliates" ADD COLUMN "commission_type" commission_type;
    ALTER TABLE "affiliates" ALTER COLUMN "commission_type" SET DEFAULT 'percentage'::commission_type;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'business_name') THEN
    ALTER TABLE "affiliates" ADD COLUMN "business_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'tax_id') THEN
    ALTER TABLE "affiliates" ADD COLUMN "tax_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'address') THEN
    ALTER TABLE "affiliates" ADD COLUMN "address" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'payment_details') THEN
    ALTER TABLE "affiliates" ADD COLUMN "payment_details" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'total_referrals') THEN
    ALTER TABLE "affiliates" ADD COLUMN "total_referrals" integer;
    ALTER TABLE "affiliates" ALTER COLUMN "total_referrals" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'successful_referrals') THEN
    ALTER TABLE "affiliates" ADD COLUMN "successful_referrals" integer;
    ALTER TABLE "affiliates" ALTER COLUMN "successful_referrals" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'total_earnings') THEN
    ALTER TABLE "affiliates" ADD COLUMN "total_earnings" numeric;
    ALTER TABLE "affiliates" ALTER COLUMN "total_earnings" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'pending_earnings') THEN
    ALTER TABLE "affiliates" ADD COLUMN "pending_earnings" numeric;
    ALTER TABLE "affiliates" ALTER COLUMN "pending_earnings" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'paid_earnings') THEN
    ALTER TABLE "affiliates" ADD COLUMN "paid_earnings" numeric;
    ALTER TABLE "affiliates" ALTER COLUMN "paid_earnings" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'notes') THEN
    ALTER TABLE "affiliates" ADD COLUMN "notes" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'metadata') THEN
    ALTER TABLE "affiliates" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "affiliates" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'is_active') THEN
    ALTER TABLE "affiliates" ADD COLUMN "is_active" boolean;
    ALTER TABLE "affiliates" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliates' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'id') THEN
    ALTER TABLE "messages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'conversation_id') THEN
    ALTER TABLE "messages" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'external_id') THEN
    ALTER TABLE "messages" ADD COLUMN "external_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'direction') THEN
    ALTER TABLE "messages" ADD COLUMN "direction" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'type') THEN
    ALTER TABLE "messages" ADD COLUMN "type" text;
    ALTER TABLE "messages" ALTER COLUMN "type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'content') THEN
    ALTER TABLE "messages" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'metadata') THEN
    ALTER TABLE "messages" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_id') THEN
    ALTER TABLE "messages" ADD COLUMN "sender_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_type') THEN
    ALTER TABLE "messages" ADD COLUMN "sender_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'status') THEN
    ALTER TABLE "messages" ADD COLUMN "status" text;
    ALTER TABLE "messages" ALTER COLUMN "status" SET DEFAULT 'sent'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sent_at') THEN
    ALTER TABLE "messages" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'read_at') THEN
    ALTER TABLE "messages" ADD COLUMN "read_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'is_from_bot') THEN
    ALTER TABLE "messages" ADD COLUMN "is_from_bot" boolean;
    ALTER TABLE "messages" ALTER COLUMN "is_from_bot" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'media_url') THEN
    ALTER TABLE "messages" ADD COLUMN "media_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'group_participant_jid') THEN
    ALTER TABLE "messages" ADD COLUMN "group_participant_jid" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'group_participant_name') THEN
    ALTER TABLE "messages" ADD COLUMN "group_participant_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'created_at') THEN
    ALTER TABLE "messages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "messages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_message_id') THEN
    ALTER TABLE "messages" ADD COLUMN "email_message_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_in_reply_to') THEN
    ALTER TABLE "messages" ADD COLUMN "email_in_reply_to" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_references') THEN
    ALTER TABLE "messages" ADD COLUMN "email_references" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_subject') THEN
    ALTER TABLE "messages" ADD COLUMN "email_subject" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_from') THEN
    ALTER TABLE "messages" ADD COLUMN "email_from" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_to') THEN
    ALTER TABLE "messages" ADD COLUMN "email_to" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_cc') THEN
    ALTER TABLE "messages" ADD COLUMN "email_cc" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_bcc') THEN
    ALTER TABLE "messages" ADD COLUMN "email_bcc" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_html') THEN
    ALTER TABLE "messages" ADD COLUMN "email_html" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_plain_text') THEN
    ALTER TABLE "messages" ADD COLUMN "email_plain_text" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'email_headers') THEN
    ALTER TABLE "messages" ADD COLUMN "email_headers" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'is_history_sync') THEN
    ALTER TABLE "messages" ADD COLUMN "is_history_sync" boolean;
    ALTER TABLE "messages" ALTER COLUMN "is_history_sync" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'history_sync_batch_id') THEN
    ALTER TABLE "messages" ADD COLUMN "history_sync_batch_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'plan_id') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'name') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'commission_type') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "commission_type" commission_type;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "commission_type" SET DEFAULT 'percentage'::commission_type;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'commission_value') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "commission_value" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'tier_rules') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "tier_rules" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'minimum_payout') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "minimum_payout" numeric;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "minimum_payout" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'maximum_payout') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "maximum_payout" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'recurring_commission') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "recurring_commission" boolean;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "recurring_commission" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'recurring_months') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "recurring_months" integer;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "recurring_months" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'valid_from') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "valid_from" timestamp without time zone;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "valid_from" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'valid_until') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "valid_until" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'is_active') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "is_active" boolean;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_commission_structures' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_commission_structures" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_commission_structures" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'referral_code') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "referral_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'referred_company_id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "referred_company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'referred_user_id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "referred_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'referred_email') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "referred_email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'status') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "status" referral_status;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "status" SET DEFAULT 'pending'::referral_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'converted_at') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "converted_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'conversion_value') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "conversion_value" numeric;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "conversion_value" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'commission_structure_id') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "commission_structure_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'commission_amount') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "commission_amount" numeric;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "commission_amount" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'commission_rate') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "commission_rate" numeric;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "commission_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'source_url') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "source_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'utm_source') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "utm_source" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'utm_medium') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "utm_medium" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'utm_campaign') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "utm_campaign" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'utm_content') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "utm_content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'utm_term') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "utm_term" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'user_agent') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'ip_address') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "ip_address" inet;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'country_code') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "country_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'expires_at') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'metadata') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_referrals' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_referrals" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_referrals" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'amount') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'currency') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "currency" text;
    ALTER TABLE "affiliate_payouts" ALTER COLUMN "currency" SET DEFAULT 'USD'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'status') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "status" payout_status;
    ALTER TABLE "affiliate_payouts" ALTER COLUMN "status" SET DEFAULT 'pending'::payout_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'payment_method') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "payment_method" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'payment_reference') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "payment_reference" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'external_transaction_id') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "external_transaction_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'period_start') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "period_start" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'period_end') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "period_end" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'processed_by') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "processed_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'processed_at') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "processed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'failure_reason') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "failure_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'referral_ids') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "referral_ids" int4[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'notes') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "notes" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'metadata') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "affiliate_payouts" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_payouts" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_payouts' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_payouts" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_payouts" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'date') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "date" date;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'period_type') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "period_type" text;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "period_type" SET DEFAULT 'daily'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'clicks') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "clicks" integer;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "clicks" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'unique_clicks') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "unique_clicks" integer;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "unique_clicks" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'impressions') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "impressions" integer;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "impressions" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'referrals') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "referrals" integer;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "referrals" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'conversions') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "conversions" integer;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "conversions" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'conversion_rate') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "conversion_rate" numeric;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "conversion_rate" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'revenue') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "revenue" numeric;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "revenue" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'commission_earned') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "commission_earned" numeric;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "commission_earned" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'average_order_value') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "average_order_value" numeric;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "average_order_value" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'top_countries') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "top_countries" jsonb;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "top_countries" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'top_sources') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "top_sources" jsonb;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "top_sources" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_analytics' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_analytics" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_analytics" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'referral_id') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "referral_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'clicked_url') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "clicked_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'landing_page') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "landing_page" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'session_id') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'user_agent') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'ip_address') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "ip_address" inet;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'country_code') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "country_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'city') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "city" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'utm_source') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "utm_source" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'utm_medium') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "utm_medium" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'utm_campaign') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "utm_campaign" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'utm_content') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "utm_content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'utm_term') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "utm_term" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'referrer_url') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "referrer_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'referrer_domain') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "referrer_domain" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'device_type') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "device_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'browser') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "browser" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'os') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "os" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'converted') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "converted" boolean;
    ALTER TABLE "affiliate_clicks" ALTER COLUMN "converted" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'converted_at') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "converted_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_clicks' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_clicks" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_clicks" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'parent_affiliate_id') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "parent_affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'child_affiliate_id') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "child_affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'level') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "level" integer;
    ALTER TABLE "affiliate_relationships" ALTER COLUMN "level" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'commission_percentage') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "commission_percentage" numeric;
    ALTER TABLE "affiliate_relationships" ALTER COLUMN "commission_percentage" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'is_active') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "is_active" boolean;
    ALTER TABLE "affiliate_relationships" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_relationships" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_relationships' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_relationships" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_relationships" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'first_name') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "first_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'last_name') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "last_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'email') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "email" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'phone') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "phone" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'company') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "company" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'website') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "website" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'country') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "country" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'marketing_channels') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "marketing_channels" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'expected_monthly_referrals') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "expected_monthly_referrals" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'experience') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "experience" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'motivation') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "motivation" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'status') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "status" affiliate_application_status;
    ALTER TABLE "affiliate_applications" ALTER COLUMN "status" SET DEFAULT 'pending'::affiliate_application_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'agree_to_terms') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "agree_to_terms" boolean;
    ALTER TABLE "affiliate_applications" ALTER COLUMN "agree_to_terms" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'reviewed_by') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "reviewed_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'reviewed_at') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "reviewed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'review_notes') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "review_notes" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'rejection_reason') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "rejection_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'submitted_at') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "submitted_at" timestamp without time zone;
    ALTER TABLE "affiliate_applications" ALTER COLUMN "submitted_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_applications" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_applications' AND column_name = 'updated_at') THEN
    ALTER TABLE "affiliate_applications" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "affiliate_applications" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'id') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'company_id') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'code') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'name') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'description') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'discount_type') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "discount_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'discount_value') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "discount_value" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'usage_limit') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "usage_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'usage_limit_per_user') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "usage_limit_per_user" integer;
    ALTER TABLE "coupon_codes" ALTER COLUMN "usage_limit_per_user" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'current_usage_count') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "current_usage_count" integer;
    ALTER TABLE "coupon_codes" ALTER COLUMN "current_usage_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'start_date') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "start_date" timestamp without time zone;
    ALTER TABLE "coupon_codes" ALTER COLUMN "start_date" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'end_date') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "end_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'applicable_plan_ids') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "applicable_plan_ids" int4[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'minimum_plan_value') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "minimum_plan_value" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'is_active') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "is_active" boolean;
    ALTER TABLE "coupon_codes" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'created_by') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'metadata') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "coupon_codes" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'created_at') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "coupon_codes" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_codes' AND column_name = 'updated_at') THEN
    ALTER TABLE "coupon_codes" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "coupon_codes" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'coupon_id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "coupon_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'company_id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'user_id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'plan_id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'original_amount') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "original_amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'discount_amount') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "discount_amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'final_amount') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "final_amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'payment_transaction_id') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "payment_transaction_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'usage_context') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "usage_context" jsonb;
    ALTER TABLE "coupon_usage" ALTER COLUMN "usage_context" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'coupon_usage' AND column_name = 'created_at') THEN
    ALTER TABLE "coupon_usage" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "coupon_usage" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'total_earned') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "total_earned" numeric;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "total_earned" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'available_balance') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "available_balance" numeric;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "available_balance" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'applied_to_plans') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "applied_to_plans" numeric;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "applied_to_plans" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'pending_payout') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "pending_payout" numeric;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "pending_payout" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'paid_out') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "paid_out" numeric;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "paid_out" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'last_updated') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "last_updated" timestamp without time zone;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "last_updated" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_balance' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_earnings_balance" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_earnings_balance" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'company_id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'affiliate_id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "affiliate_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'transaction_type') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "transaction_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'amount') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "amount" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'balance_after') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "balance_after" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'referral_id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "referral_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'payment_transaction_id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "payment_transaction_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'payout_id') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "payout_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'description') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'metadata') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "affiliate_earnings_transactions" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'affiliate_earnings_transactions' AND column_name = 'created_at') THEN
    ALTER TABLE "affiliate_earnings_transactions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "affiliate_earnings_transactions" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'id') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'company_id') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'default_provider') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "default_provider" VARCHAR(50);
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "default_provider" SET DEFAULT 'gemini'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'credential_preference') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "credential_preference" VARCHAR(20);
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "credential_preference" SET DEFAULT 'system'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'fallback_enabled') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "fallback_enabled" boolean;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "fallback_enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'usage_alerts_enabled') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "usage_alerts_enabled" boolean;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "usage_alerts_enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'usage_alert_threshold') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "usage_alert_threshold" integer;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "usage_alert_threshold" SET DEFAULT 80;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'metadata') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'created_at') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_preferences' AND column_name = 'updated_at') THEN
    ALTER TABLE "company_ai_preferences" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "company_ai_preferences" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'company_id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'credential_type') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "credential_type" VARCHAR(20);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'credential_id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "credential_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'provider') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'model') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "model" VARCHAR(100);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'tokens_input') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "tokens_input" integer;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "tokens_input" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'tokens_output') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "tokens_output" integer;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "tokens_output" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'tokens_total') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "tokens_total" integer;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "tokens_total" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'cost_estimated') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "cost_estimated" numeric;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "cost_estimated" SET DEFAULT 0.00;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'request_count') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "request_count" integer;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "request_count" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'conversation_id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'flow_id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'node_id') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "node_id" VARCHAR(100);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'usage_date') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "usage_date" date;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "usage_date" SET DEFAULT CURRENT_DATE;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_credential_usage' AND column_name = 'created_at') THEN
    ALTER TABLE "ai_credential_usage" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "ai_credential_usage" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'id') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'plan_id') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'provider') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'tokens_monthly_limit') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "tokens_monthly_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'tokens_daily_limit') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "tokens_daily_limit" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'custom_pricing_enabled') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "custom_pricing_enabled" boolean;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "custom_pricing_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'input_token_rate') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "input_token_rate" numeric;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "input_token_rate" SET DEFAULT NULL::numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'output_token_rate') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "output_token_rate" numeric;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "output_token_rate" SET DEFAULT NULL::numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'enabled') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "enabled" boolean;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'priority') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "priority" integer;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "priority" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'metadata') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'created_at') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_provider_configs' AND column_name = 'updated_at') THEN
    ALTER TABLE "plan_ai_provider_configs" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "plan_ai_provider_configs" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'id') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'company_id') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'plan_id') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'provider') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'tokens_used_monthly') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "tokens_used_monthly" integer;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "tokens_used_monthly" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'tokens_used_daily') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "tokens_used_daily" integer;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "tokens_used_daily" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'requests_monthly') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "requests_monthly" integer;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "requests_monthly" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'requests_daily') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "requests_daily" integer;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "requests_daily" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'cost_monthly') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "cost_monthly" numeric;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "cost_monthly" SET DEFAULT 0.000000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'cost_daily') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "cost_daily" numeric;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "cost_daily" SET DEFAULT 0.000000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'overage_tokens_monthly') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "overage_tokens_monthly" integer;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "overage_tokens_monthly" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'overage_cost_monthly') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "overage_cost_monthly" numeric;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "overage_cost_monthly" SET DEFAULT 0.000000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'usage_month') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "usage_month" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'usage_year') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "usage_year" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'usage_date') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "usage_date" date;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'monthly_limit_reached') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "monthly_limit_reached" boolean;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "monthly_limit_reached" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'daily_limit_reached') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "daily_limit_reached" boolean;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "daily_limit_reached" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'monthly_warning_sent') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "monthly_warning_sent" boolean;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "monthly_warning_sent" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'daily_warning_sent') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "daily_warning_sent" boolean;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "daily_warning_sent" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'created_at') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_usage_tracking' AND column_name = 'updated_at') THEN
    ALTER TABLE "plan_ai_usage_tracking" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "plan_ai_usage_tracking" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'id') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'company_id') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'plan_id') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'provider') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'event_type') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "event_type" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'event_data') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "event_data" jsonb;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "event_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'tokens_consumed') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "tokens_consumed" integer;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "tokens_consumed" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'cost_amount') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "cost_amount" numeric;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "cost_amount" SET DEFAULT 0.000000;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'billing_period_start') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "billing_period_start" date;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'billing_period_end') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "billing_period_end" date;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'processed') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "processed" boolean;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "processed" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'processed_at') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "processed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'created_at') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'plan_ai_billing_events' AND column_name = 'metadata') THEN
    ALTER TABLE "plan_ai_billing_events" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "plan_ai_billing_events" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'id') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'provider') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'api_key_encrypted') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "api_key_encrypted" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'display_name') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "display_name" VARCHAR(100);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'description') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'is_active') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "is_active" boolean;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'is_default') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "is_default" boolean;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "is_default" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'usage_limit_monthly') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "usage_limit_monthly" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'usage_count_current') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "usage_count_current" integer;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "usage_count_current" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'last_validated_at') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "last_validated_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'validation_status') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "validation_status" VARCHAR(20);
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "validation_status" SET DEFAULT 'pending'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'validation_error') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "validation_error" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'metadata') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'created_at') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_ai_credentials' AND column_name = 'updated_at') THEN
    ALTER TABLE "system_ai_credentials" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "system_ai_credentials" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'id') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'company_id') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'provider') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "provider" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'api_key_encrypted') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "api_key_encrypted" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'display_name') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "display_name" VARCHAR(100);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'description') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'is_active') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "is_active" boolean;
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'usage_limit_monthly') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "usage_limit_monthly" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'usage_count_current') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "usage_count_current" integer;
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "usage_count_current" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'last_validated_at') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "last_validated_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'validation_status') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "validation_status" VARCHAR(20);
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "validation_status" SET DEFAULT 'pending'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'validation_error') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "validation_error" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'metadata') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'created_at') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_ai_credentials' AND column_name = 'updated_at') THEN
    ALTER TABLE "company_ai_credentials" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "company_ai_credentials" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'id') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'company_id') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'event_type') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "event_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'event_data') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "event_data" jsonb;
    ALTER TABLE "subscription_events" ALTER COLUMN "event_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'previous_status') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "previous_status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'new_status') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "new_status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'triggered_by') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "triggered_by" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_events' AND column_name = 'created_at') THEN
    ALTER TABLE "subscription_events" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "subscription_events" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'id') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'company_id') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'metric_name') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "metric_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'current_usage') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "current_usage" integer;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "current_usage" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'limit_value') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "limit_value" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'soft_limit_reached') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "soft_limit_reached" boolean;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "soft_limit_reached" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'hard_limit_reached') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "hard_limit_reached" boolean;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "hard_limit_reached" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'last_warning_sent') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "last_warning_sent" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'reset_period') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "reset_period" text;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "reset_period" SET DEFAULT 'monthly'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'last_reset') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "last_reset" timestamp without time zone;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "last_reset" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'created_at') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_usage_tracking' AND column_name = 'updated_at') THEN
    ALTER TABLE "subscription_usage_tracking" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "subscription_usage_tracking" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'id') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'company_id') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'payment_transaction_id') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "payment_transaction_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'attempt_number') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "attempt_number" integer;
    ALTER TABLE "dunning_management" ALTER COLUMN "attempt_number" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'attempt_date') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "attempt_date" timestamp without time zone;
    ALTER TABLE "dunning_management" ALTER COLUMN "attempt_date" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'attempt_type') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "attempt_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'status') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "status" text;
    ALTER TABLE "dunning_management" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'response_data') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "response_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'next_attempt_date') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "next_attempt_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dunning_management' AND column_name = 'created_at') THEN
    ALTER TABLE "dunning_management" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "dunning_management" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'id') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'company_id') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'from_plan_id') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "from_plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'to_plan_id') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "to_plan_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'change_type') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "change_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'effective_date') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "effective_date" timestamp without time zone;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "effective_date" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'proration_amount') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "proration_amount" numeric;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "proration_amount" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'proration_days') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "proration_days" integer;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "proration_days" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'billing_cycle_reset') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "billing_cycle_reset" boolean;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "billing_cycle_reset" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'change_reason') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "change_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'processed') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "processed" boolean;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "processed" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plan_changes' AND column_name = 'created_at') THEN
    ALTER TABLE "subscription_plan_changes" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "subscription_plan_changes" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'id') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'company_id') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'notification_type') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "notification_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'status') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "status" text;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'scheduled_for') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "scheduled_for" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'sent_at') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'notification_data') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "notification_data" jsonb;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "notification_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'delivery_method') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "delivery_method" text;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "delivery_method" SET DEFAULT 'email'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'retry_count') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "retry_count" integer;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "retry_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'max_retries') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "max_retries" integer;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "max_retries" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_notifications' AND column_name = 'created_at') THEN
    ALTER TABLE "subscription_notifications" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "subscription_notifications" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'schedule_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "schedule_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'session_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "session_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'flow_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'conversation_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'contact_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'company_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'node_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'message_type') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "message_type" text;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "message_type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'message_content') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "message_content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'media_url') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "media_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'caption') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "caption" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'template_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "template_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'trigger_event') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "trigger_event" text;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "trigger_event" SET DEFAULT 'conversation_start'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'trigger_node_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "trigger_node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'delay_amount') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "delay_amount" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'delay_unit') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "delay_unit" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'scheduled_for') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "scheduled_for" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'specific_datetime') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "specific_datetime" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'status') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "status" text;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "status" SET DEFAULT 'scheduled'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'sent_at') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'failed_reason') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "failed_reason" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'retry_count') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "retry_count" integer;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "retry_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'max_retries') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "max_retries" integer;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "max_retries" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'channel_type') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "channel_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'channel_connection_id') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "channel_connection_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'variables') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "variables" jsonb;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "variables" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'execution_context') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "execution_context" jsonb;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "execution_context" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'created_at') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'updated_at') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'expires_at') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'follow_up_schedules' AND column_name = 'timezone') THEN
    ALTER TABLE "follow_up_schedules" ADD COLUMN "timezone" text;
    ALTER TABLE "follow_up_schedules" ALTER COLUMN "timezone" SET DEFAULT 'UTC'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'id') THEN
    ALTER TABLE "website_templates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'name') THEN
    ALTER TABLE "website_templates" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'description') THEN
    ALTER TABLE "website_templates" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'category') THEN
    ALTER TABLE "website_templates" ADD COLUMN "category" text;
    ALTER TABLE "website_templates" ALTER COLUMN "category" SET DEFAULT 'general'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'preview_image') THEN
    ALTER TABLE "website_templates" ADD COLUMN "preview_image" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'preview_url') THEN
    ALTER TABLE "website_templates" ADD COLUMN "preview_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'grapes_data') THEN
    ALTER TABLE "website_templates" ADD COLUMN "grapes_data" jsonb;
    ALTER TABLE "website_templates" ALTER COLUMN "grapes_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'grapes_html') THEN
    ALTER TABLE "website_templates" ADD COLUMN "grapes_html" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'grapes_css') THEN
    ALTER TABLE "website_templates" ADD COLUMN "grapes_css" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'grapes_js') THEN
    ALTER TABLE "website_templates" ADD COLUMN "grapes_js" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'is_active') THEN
    ALTER TABLE "website_templates" ADD COLUMN "is_active" boolean;
    ALTER TABLE "website_templates" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'is_premium') THEN
    ALTER TABLE "website_templates" ADD COLUMN "is_premium" boolean;
    ALTER TABLE "website_templates" ALTER COLUMN "is_premium" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'tags') THEN
    ALTER TABLE "website_templates" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'usage_count') THEN
    ALTER TABLE "website_templates" ADD COLUMN "usage_count" integer;
    ALTER TABLE "website_templates" ALTER COLUMN "usage_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'created_by_id') THEN
    ALTER TABLE "website_templates" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'created_at') THEN
    ALTER TABLE "website_templates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "website_templates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_templates' AND column_name = 'updated_at') THEN
    ALTER TABLE "website_templates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "website_templates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'id') THEN
    ALTER TABLE "websites" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'title') THEN
    ALTER TABLE "websites" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'slug') THEN
    ALTER TABLE "websites" ADD COLUMN "slug" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'description') THEN
    ALTER TABLE "websites" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'meta_title') THEN
    ALTER TABLE "websites" ADD COLUMN "meta_title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'meta_description') THEN
    ALTER TABLE "websites" ADD COLUMN "meta_description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'meta_keywords') THEN
    ALTER TABLE "websites" ADD COLUMN "meta_keywords" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'grapes_data') THEN
    ALTER TABLE "websites" ADD COLUMN "grapes_data" jsonb;
    ALTER TABLE "websites" ALTER COLUMN "grapes_data" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'grapes_html') THEN
    ALTER TABLE "websites" ADD COLUMN "grapes_html" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'grapes_css') THEN
    ALTER TABLE "websites" ADD COLUMN "grapes_css" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'grapes_js') THEN
    ALTER TABLE "websites" ADD COLUMN "grapes_js" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'favicon') THEN
    ALTER TABLE "websites" ADD COLUMN "favicon" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'custom_css') THEN
    ALTER TABLE "websites" ADD COLUMN "custom_css" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'custom_js') THEN
    ALTER TABLE "websites" ADD COLUMN "custom_js" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'custom_head') THEN
    ALTER TABLE "websites" ADD COLUMN "custom_head" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'status') THEN
    ALTER TABLE "websites" ADD COLUMN "status" text;
    ALTER TABLE "websites" ALTER COLUMN "status" SET DEFAULT 'draft'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'published_at') THEN
    ALTER TABLE "websites" ADD COLUMN "published_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'google_analytics_id') THEN
    ALTER TABLE "websites" ADD COLUMN "google_analytics_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'facebook_pixel_id') THEN
    ALTER TABLE "websites" ADD COLUMN "facebook_pixel_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'template_id') THEN
    ALTER TABLE "websites" ADD COLUMN "template_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'theme') THEN
    ALTER TABLE "websites" ADD COLUMN "theme" text;
    ALTER TABLE "websites" ALTER COLUMN "theme" SET DEFAULT 'default'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'created_by_id') THEN
    ALTER TABLE "websites" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'created_at') THEN
    ALTER TABLE "websites" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "websites" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'websites' AND column_name = 'updated_at') THEN
    ALTER TABLE "websites" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "websites" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'id') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'company_id') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'node_id') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'filename') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'original_name') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "original_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'mime_type') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "mime_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'file_size') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "file_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'status') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "status" text;
    ALTER TABLE "knowledge_base_documents" ALTER COLUMN "status" SET DEFAULT 'uploading'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'file_path') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "file_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'file_url') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "file_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'extracted_text') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "extracted_text" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'chunk_count') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "chunk_count" integer;
    ALTER TABLE "knowledge_base_documents" ALTER COLUMN "chunk_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'embedding_model') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "embedding_model" text;
    ALTER TABLE "knowledge_base_documents" ALTER COLUMN "embedding_model" SET DEFAULT 'text-embedding-3-small'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'processing_error') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "processing_error" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'processing_duration_ms') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "processing_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'created_at') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_documents" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_documents' AND column_name = 'updated_at') THEN
    ALTER TABLE "knowledge_base_documents" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_documents" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'id') THEN
    ALTER TABLE "website_assets" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'website_id') THEN
    ALTER TABLE "website_assets" ADD COLUMN "website_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'filename') THEN
    ALTER TABLE "website_assets" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'original_name') THEN
    ALTER TABLE "website_assets" ADD COLUMN "original_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'mime_type') THEN
    ALTER TABLE "website_assets" ADD COLUMN "mime_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'size') THEN
    ALTER TABLE "website_assets" ADD COLUMN "size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'path') THEN
    ALTER TABLE "website_assets" ADD COLUMN "path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'url') THEN
    ALTER TABLE "website_assets" ADD COLUMN "url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'alt') THEN
    ALTER TABLE "website_assets" ADD COLUMN "alt" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'title') THEN
    ALTER TABLE "website_assets" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'asset_type') THEN
    ALTER TABLE "website_assets" ADD COLUMN "asset_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'created_at') THEN
    ALTER TABLE "website_assets" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "website_assets" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'website_assets' AND column_name = 'updated_at') THEN
    ALTER TABLE "website_assets" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "website_assets" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'id') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'company_id') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'created_by_id') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "created_by_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'name') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'content') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'category') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "category" text;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "category" SET DEFAULT 'general'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'variables') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "variables" jsonb;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "variables" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'is_active') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "is_active" boolean;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'usage_count') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "usage_count" integer;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "usage_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'sort_order') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "sort_order" integer;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "sort_order" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'created_at') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quick_reply_templates' AND column_name = 'updated_at') THEN
    ALTER TABLE "quick_reply_templates" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "quick_reply_templates" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'id') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'document_id') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "document_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'content') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'chunk_index') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "chunk_index" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'token_count') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "token_count" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'start_position') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "start_position" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'end_position') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "end_position" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_chunks' AND column_name = 'created_at') THEN
    ALTER TABLE "knowledge_base_chunks" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_chunks" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'id') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'company_id') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'node_id') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'flow_id') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'enabled') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "enabled" boolean;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'max_retrieved_chunks') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "max_retrieved_chunks" integer;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "max_retrieved_chunks" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'similarity_threshold') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "similarity_threshold" real;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "similarity_threshold" SET DEFAULT 0.7;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'embedding_model') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "embedding_model" text;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "embedding_model" SET DEFAULT 'text-embedding-3-small'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'context_position') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "context_position" text;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "context_position" SET DEFAULT 'before_system'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'context_template') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "context_template" text;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "context_template" SET DEFAULT 'Based on the following knowledge base information:

{context}

Please answer the user''s question using this information when relevant.'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'created_at') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_configs' AND column_name = 'updated_at') THEN
    ALTER TABLE "knowledge_base_configs" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_configs" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'id') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'document_id') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "document_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'company_id') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'node_id') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'flow_id') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "flow_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_document_nodes' AND column_name = 'created_at') THEN
    ALTER TABLE "knowledge_base_document_nodes" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_document_nodes" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'id') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'company_id') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'node_id') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "node_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'document_id') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "document_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'query_text') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "query_text" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'query_embedding') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "query_embedding" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'chunks_retrieved') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "chunks_retrieved" integer;
    ALTER TABLE "knowledge_base_usage" ALTER COLUMN "chunks_retrieved" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'chunks_used') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "chunks_used" integer;
    ALTER TABLE "knowledge_base_usage" ALTER COLUMN "chunks_used" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'similarity_scores') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "similarity_scores" jsonb;
    ALTER TABLE "knowledge_base_usage" ALTER COLUMN "similarity_scores" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'retrieval_duration_ms') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "retrieval_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'embedding_duration_ms') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "embedding_duration_ms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'context_injected') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "context_injected" boolean;
    ALTER TABLE "knowledge_base_usage" ALTER COLUMN "context_injected" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'context_length') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "context_length" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'knowledge_base_usage' AND column_name = 'created_at') THEN
    ALTER TABLE "knowledge_base_usage" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "knowledge_base_usage" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'id') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'contact_id') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'filename') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'original_name') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "original_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'mime_type') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "mime_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'file_size') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "file_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'file_path') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "file_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'file_url') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "file_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'category') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "category" text;
    ALTER TABLE "contact_documents" ALTER COLUMN "category" SET DEFAULT 'general'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'description') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'uploaded_by') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "uploaded_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'created_at') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "contact_documents" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_documents' AND column_name = 'updated_at') THEN
    ALTER TABLE "contact_documents" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "contact_documents" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'id') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'contact_id') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'title') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'description') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'location') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "location" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'scheduled_at') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "scheduled_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'duration_minutes') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "duration_minutes" integer;
    ALTER TABLE "contact_appointments" ALTER COLUMN "duration_minutes" SET DEFAULT 60;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'type') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "type" text;
    ALTER TABLE "contact_appointments" ALTER COLUMN "type" SET DEFAULT 'meeting'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'status') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "status" text;
    ALTER TABLE "contact_appointments" ALTER COLUMN "status" SET DEFAULT 'scheduled'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'created_by') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'created_at') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "contact_appointments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_appointments' AND column_name = 'updated_at') THEN
    ALTER TABLE "contact_appointments" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "contact_appointments" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'id') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'user_id') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'company_id') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'access_token') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'refresh_token') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "refresh_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'token_type') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "token_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'expires_in') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "expires_in" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'scope') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "scope" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'created_at') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "zoho_calendar_tokens" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zoho_calendar_tokens' AND column_name = 'updated_at') THEN
    ALTER TABLE "zoho_calendar_tokens" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "zoho_calendar_tokens" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'id') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'connection_id') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "connection_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'company_id') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'batch_id') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "batch_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'sync_type') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "sync_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'status') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "status" text;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'total_chats') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "total_chats" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "total_chats" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'processed_chats') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "processed_chats" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "processed_chats" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'total_messages') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "total_messages" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "total_messages" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'processed_messages') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "processed_messages" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "processed_messages" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'total_contacts') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "total_contacts" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "total_contacts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'processed_contacts') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "processed_contacts" integer;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "processed_contacts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'error_message') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'started_at') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "started_at" timestamp without time zone;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "started_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'completed_at') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'created_at') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'history_sync_batches' AND column_name = 'updated_at') THEN
    ALTER TABLE "history_sync_batches" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "history_sync_batches" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'id') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'company_id') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'contact_id') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'user_id') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'action_type') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "action_type" VARCHAR(50);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'action_category') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "action_category" VARCHAR(30);
    ALTER TABLE "contact_audit_logs" ALTER COLUMN "action_category" SET DEFAULT 'contact'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'description') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'old_values') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "old_values" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'new_values') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "new_values" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'metadata') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'ip_address') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "ip_address" inet;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'user_agent') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_audit_logs' AND column_name = 'created_at') THEN
    ALTER TABLE "contact_audit_logs" ADD COLUMN "created_at" timestamp with time zone;
    ALTER TABLE "contact_audit_logs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'id') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'user_id') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'company_id') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'access_token') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'refresh_token') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "refresh_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'token_type') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "token_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'expires_in') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "expires_in" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'scope') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "scope" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'created_at') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "calendly_calendar_tokens" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calendly_calendar_tokens' AND column_name = 'updated_at') THEN
    ALTER TABLE "calendly_calendar_tokens" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "calendly_calendar_tokens" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'id') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'company_id') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'backup_id') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "backup_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'restored_by_user_id') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "restored_by_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'status') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "status" restore_status;
    ALTER TABLE "inbox_restores" ALTER COLUMN "status" SET DEFAULT 'pending'::restore_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'restore_type') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "restore_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'conflict_resolution') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "conflict_resolution" text;
    ALTER TABLE "inbox_restores" ALTER COLUMN "conflict_resolution" SET DEFAULT 'merge'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'date_range_start') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "date_range_start" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'date_range_end') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "date_range_end" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'restore_contacts') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "restore_contacts" boolean;
    ALTER TABLE "inbox_restores" ALTER COLUMN "restore_contacts" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'restore_conversations') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "restore_conversations" boolean;
    ALTER TABLE "inbox_restores" ALTER COLUMN "restore_conversations" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'restore_messages') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "restore_messages" boolean;
    ALTER TABLE "inbox_restores" ALTER COLUMN "restore_messages" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'total_items_to_restore') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "total_items_to_restore" integer;
    ALTER TABLE "inbox_restores" ALTER COLUMN "total_items_to_restore" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'items_restored') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "items_restored" integer;
    ALTER TABLE "inbox_restores" ALTER COLUMN "items_restored" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'items_skipped') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "items_skipped" integer;
    ALTER TABLE "inbox_restores" ALTER COLUMN "items_skipped" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'items_errored') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "items_errored" integer;
    ALTER TABLE "inbox_restores" ALTER COLUMN "items_errored" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'error_message') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'started_at') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'completed_at') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'created_at') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "inbox_restores" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_restores' AND column_name = 'updated_at') THEN
    ALTER TABLE "inbox_restores" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "inbox_restores" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'id') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'company_id') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'created_by_user_id') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "created_by_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'name') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'description') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'is_active') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "is_active" boolean;
    ALTER TABLE "backup_schedules" ALTER COLUMN "is_active" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'frequency') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "frequency" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'cron_expression') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "cron_expression" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'retention_days') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "retention_days" integer;
    ALTER TABLE "backup_schedules" ALTER COLUMN "retention_days" SET DEFAULT 30;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'include_contacts') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "include_contacts" boolean;
    ALTER TABLE "backup_schedules" ALTER COLUMN "include_contacts" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'include_conversations') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "include_conversations" boolean;
    ALTER TABLE "backup_schedules" ALTER COLUMN "include_conversations" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'include_messages') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "include_messages" boolean;
    ALTER TABLE "backup_schedules" ALTER COLUMN "include_messages" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'last_run_at') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "last_run_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'next_run_at') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "next_run_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'created_at') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "backup_schedules" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'updated_at') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "backup_schedules" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_schedules' AND column_name = 'enabled') THEN
    ALTER TABLE "backup_schedules" ADD COLUMN "enabled" boolean;
    ALTER TABLE "backup_schedules" ALTER COLUMN "enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'id') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'company_id') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'created_by_user_id') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "created_by_user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'name') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'description') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'type') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "type" backup_type;
    ALTER TABLE "inbox_backups" ALTER COLUMN "type" SET DEFAULT 'manual'::backup_type;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'status') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "status" backup_status;
    ALTER TABLE "inbox_backups" ALTER COLUMN "status" SET DEFAULT 'pending'::backup_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'file_path') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "file_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'file_name') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "file_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'file_size') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "file_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'compressed_size') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "compressed_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'checksum') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "checksum" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'metadata') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "inbox_backups" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'include_contacts') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "include_contacts" boolean;
    ALTER TABLE "inbox_backups" ALTER COLUMN "include_contacts" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'include_conversations') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "include_conversations" boolean;
    ALTER TABLE "inbox_backups" ALTER COLUMN "include_conversations" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'include_messages') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "include_messages" boolean;
    ALTER TABLE "inbox_backups" ALTER COLUMN "include_messages" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'date_range_start') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "date_range_start" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'date_range_end') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "date_range_end" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'total_contacts') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "total_contacts" integer;
    ALTER TABLE "inbox_backups" ALTER COLUMN "total_contacts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'total_conversations') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "total_conversations" integer;
    ALTER TABLE "inbox_backups" ALTER COLUMN "total_conversations" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'total_messages') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "total_messages" integer;
    ALTER TABLE "inbox_backups" ALTER COLUMN "total_messages" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'error_message') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'started_at') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'completed_at') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'expires_at') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'created_at') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "inbox_backups" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'inbox_backups' AND column_name = 'updated_at') THEN
    ALTER TABLE "inbox_backups" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "inbox_backups" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'id') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'company_id') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'user_id') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'action') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "action" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'entity_type') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "entity_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'entity_id') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "entity_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'details') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "details" jsonb;
    ALTER TABLE "backup_audit_logs" ALTER COLUMN "details" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'ip_address') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "ip_address" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'user_agent') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "user_agent" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'backup_audit_logs' AND column_name = 'created_at') THEN
    ALTER TABLE "backup_audit_logs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "backup_audit_logs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'id') THEN
    ALTER TABLE "calls" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'company_id') THEN
    ALTER TABLE "calls" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'channel_id') THEN
    ALTER TABLE "calls" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'contact_id') THEN
    ALTER TABLE "calls" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'conversation_id') THEN
    ALTER TABLE "calls" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'direction') THEN
    ALTER TABLE "calls" ADD COLUMN "direction" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'status') THEN
    ALTER TABLE "calls" ADD COLUMN "status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'from') THEN
    ALTER TABLE "calls" ADD COLUMN "from" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'to') THEN
    ALTER TABLE "calls" ADD COLUMN "to" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'duration_sec') THEN
    ALTER TABLE "calls" ADD COLUMN "duration_sec" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'started_at') THEN
    ALTER TABLE "calls" ADD COLUMN "started_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'ended_at') THEN
    ALTER TABLE "calls" ADD COLUMN "ended_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'recording_url') THEN
    ALTER TABLE "calls" ADD COLUMN "recording_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'recording_sid') THEN
    ALTER TABLE "calls" ADD COLUMN "recording_sid" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'twilio_call_sid') THEN
    ALTER TABLE "calls" ADD COLUMN "twilio_call_sid" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'metadata') THEN
    ALTER TABLE "calls" ADD COLUMN "metadata" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'calls' AND column_name = 'created_at') THEN
    ALTER TABLE "calls" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "calls" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'id') THEN
    ALTER TABLE "task_categories" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'company_id') THEN
    ALTER TABLE "task_categories" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'name') THEN
    ALTER TABLE "task_categories" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'color') THEN
    ALTER TABLE "task_categories" ADD COLUMN "color" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'icon') THEN
    ALTER TABLE "task_categories" ADD COLUMN "icon" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'created_by') THEN
    ALTER TABLE "task_categories" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'created_at') THEN
    ALTER TABLE "task_categories" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "task_categories" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'task_categories' AND column_name = 'updated_at') THEN
    ALTER TABLE "task_categories" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "task_categories" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'id') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'company_id') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'conversation_id') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "conversation_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'channel_id') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "channel_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'channel_type') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "channel_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'content') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'message_type') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "message_type" text;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "message_type" SET DEFAULT 'text'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'media_url') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "media_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'media_type') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "media_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'caption') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "caption" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'scheduled_for') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "scheduled_for" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'timezone') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "timezone" text;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "timezone" SET DEFAULT 'UTC'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'status') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "status" scheduled_message_status;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "status" SET DEFAULT 'pending'::scheduled_message_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'attempts') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "attempts" integer;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "attempts" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'max_attempts') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "max_attempts" integer;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "max_attempts" SET DEFAULT 3;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'last_attempt_at') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "last_attempt_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'sent_at') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "sent_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'failed_at') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "failed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'error_message') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'metadata') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'created_by') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'created_at') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'updated_at') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "scheduled_messages" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scheduled_messages' AND column_name = 'media_file_path') THEN
    ALTER TABLE "scheduled_messages" ADD COLUMN "media_file_path" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'id') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'contact_id') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'company_id') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'title') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'description') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'priority') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "priority" text;
    ALTER TABLE "contact_tasks" ALTER COLUMN "priority" SET DEFAULT 'medium'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'status') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "status" text;
    ALTER TABLE "contact_tasks" ALTER COLUMN "status" SET DEFAULT 'not_started'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'due_date') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "due_date" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'completed_at') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'assigned_to') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "assigned_to" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'category') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "category" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'tags') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'created_by') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'updated_by') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "updated_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'created_at') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "contact_tasks" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'updated_at') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "contact_tasks" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'background_color') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "background_color" VARCHAR(7);
    ALTER TABLE "contact_tasks" ALTER COLUMN "background_color" SET DEFAULT '#ffffff'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tasks' AND column_name = 'checklist') THEN
    ALTER TABLE "contact_tasks" ADD COLUMN "checklist" jsonb;
    ALTER TABLE "contact_tasks" ALTER COLUMN "checklist" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'id') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'company_id') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'name') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'enabled') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "enabled" boolean;
    ALTER TABLE "whatsapp_proxy_servers" ALTER COLUMN "enabled" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'type') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'host') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "host" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'port') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "port" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'username') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "username" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'password') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "password" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'test_status') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "test_status" text;
    ALTER TABLE "whatsapp_proxy_servers" ALTER COLUMN "test_status" SET DEFAULT 'untested'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'last_tested') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "last_tested" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'description') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'created_at') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "whatsapp_proxy_servers" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'whatsapp_proxy_servers' AND column_name = 'updated_at') THEN
    ALTER TABLE "whatsapp_proxy_servers" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "whatsapp_proxy_servers" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'id') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'user_id') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'company_id') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'channel_type') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "channel_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'account_id') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "account_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'account_name') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "account_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'access_token') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "access_token" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'status') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "status" text;
    ALTER TABLE "channel_connections" ALTER COLUMN "status" SET DEFAULT 'active'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'connection_data') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "connection_data" jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'created_at') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "channel_connections" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'updated_at') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "channel_connections" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'history_sync_enabled') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "history_sync_enabled" boolean;
    ALTER TABLE "channel_connections" ALTER COLUMN "history_sync_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'history_sync_status') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "history_sync_status" text;
    ALTER TABLE "channel_connections" ALTER COLUMN "history_sync_status" SET DEFAULT 'pending'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'history_sync_progress') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "history_sync_progress" integer;
    ALTER TABLE "channel_connections" ALTER COLUMN "history_sync_progress" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'history_sync_total') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "history_sync_total" integer;
    ALTER TABLE "channel_connections" ALTER COLUMN "history_sync_total" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'last_history_sync_at') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "last_history_sync_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'history_sync_error') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "history_sync_error" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_enabled') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_enabled" boolean;
    ALTER TABLE "channel_connections" ALTER COLUMN "proxy_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_type') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_host') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_host" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_port') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_port" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_username') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_username" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_password') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_password" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_test_status') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_test_status" text;
    ALTER TABLE "channel_connections" ALTER COLUMN "proxy_test_status" SET DEFAULT 'untested'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_last_tested') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_last_tested" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channel_connections' AND column_name = 'proxy_server_id') THEN
    ALTER TABLE "channel_connections" ADD COLUMN "proxy_server_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'id') THEN
    ALTER TABLE "database_backups" ADD COLUMN "id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'filename') THEN
    ALTER TABLE "database_backups" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'type') THEN
    ALTER TABLE "database_backups" ADD COLUMN "type" database_backup_type;
    ALTER TABLE "database_backups" ALTER COLUMN "type" SET DEFAULT 'manual'::database_backup_type;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'description') THEN
    ALTER TABLE "database_backups" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'size') THEN
    ALTER TABLE "database_backups" ADD COLUMN "size" integer;
    ALTER TABLE "database_backups" ALTER COLUMN "size" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'status') THEN
    ALTER TABLE "database_backups" ADD COLUMN "status" database_backup_status;
    ALTER TABLE "database_backups" ALTER COLUMN "status" SET DEFAULT 'creating'::database_backup_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'storage_locations') THEN
    ALTER TABLE "database_backups" ADD COLUMN "storage_locations" jsonb;
    ALTER TABLE "database_backups" ALTER COLUMN "storage_locations" SET DEFAULT '["local"]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'checksum') THEN
    ALTER TABLE "database_backups" ADD COLUMN "checksum" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'error_message') THEN
    ALTER TABLE "database_backups" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'database_size') THEN
    ALTER TABLE "database_backups" ADD COLUMN "database_size" integer;
    ALTER TABLE "database_backups" ALTER COLUMN "database_size" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'table_count') THEN
    ALTER TABLE "database_backups" ADD COLUMN "table_count" integer;
    ALTER TABLE "database_backups" ALTER COLUMN "table_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'row_count') THEN
    ALTER TABLE "database_backups" ADD COLUMN "row_count" integer;
    ALTER TABLE "database_backups" ALTER COLUMN "row_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'compression_ratio') THEN
    ALTER TABLE "database_backups" ADD COLUMN "compression_ratio" real;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'encryption_enabled') THEN
    ALTER TABLE "database_backups" ADD COLUMN "encryption_enabled" boolean;
    ALTER TABLE "database_backups" ALTER COLUMN "encryption_enabled" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'app_version') THEN
    ALTER TABLE "database_backups" ADD COLUMN "app_version" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'pg_version') THEN
    ALTER TABLE "database_backups" ADD COLUMN "pg_version" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'instance_id') THEN
    ALTER TABLE "database_backups" ADD COLUMN "instance_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'dump_format') THEN
    ALTER TABLE "database_backups" ADD COLUMN "dump_format" database_backup_format;
    ALTER TABLE "database_backups" ALTER COLUMN "dump_format" SET DEFAULT 'sql'::database_backup_format;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'schema_checksum') THEN
    ALTER TABLE "database_backups" ADD COLUMN "schema_checksum" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'created_at') THEN
    ALTER TABLE "database_backups" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "database_backups" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backups' AND column_name = 'updated_at') THEN
    ALTER TABLE "database_backups" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "database_backups" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'id') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'schedule_id') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "schedule_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'backup_id') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "backup_id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'status') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "status" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'timestamp') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "timestamp" timestamp without time zone;
    ALTER TABLE "database_backup_logs" ALTER COLUMN "timestamp" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'error_message') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "error_message" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'metadata') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "metadata" jsonb;
    ALTER TABLE "database_backup_logs" ALTER COLUMN "metadata" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'database_backup_logs' AND column_name = 'created_at') THEN
    ALTER TABLE "database_backup_logs" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "database_backup_logs" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'id') THEN
    ALTER TABLE "company_pages" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'company_id') THEN
    ALTER TABLE "company_pages" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'title') THEN
    ALTER TABLE "company_pages" ADD COLUMN "title" VARCHAR(255);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'slug') THEN
    ALTER TABLE "company_pages" ADD COLUMN "slug" VARCHAR(255);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'content') THEN
    ALTER TABLE "company_pages" ADD COLUMN "content" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'meta_title') THEN
    ALTER TABLE "company_pages" ADD COLUMN "meta_title" VARCHAR(255);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'meta_description') THEN
    ALTER TABLE "company_pages" ADD COLUMN "meta_description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'meta_keywords') THEN
    ALTER TABLE "company_pages" ADD COLUMN "meta_keywords" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'is_published') THEN
    ALTER TABLE "company_pages" ADD COLUMN "is_published" boolean;
    ALTER TABLE "company_pages" ALTER COLUMN "is_published" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'is_featured') THEN
    ALTER TABLE "company_pages" ADD COLUMN "is_featured" boolean;
    ALTER TABLE "company_pages" ALTER COLUMN "is_featured" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'template') THEN
    ALTER TABLE "company_pages" ADD COLUMN "template" VARCHAR(100);
    ALTER TABLE "company_pages" ALTER COLUMN "template" SET DEFAULT 'default'::character varying;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'custom_css') THEN
    ALTER TABLE "company_pages" ADD COLUMN "custom_css" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'custom_js') THEN
    ALTER TABLE "company_pages" ADD COLUMN "custom_js" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'author_id') THEN
    ALTER TABLE "company_pages" ADD COLUMN "author_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'published_at') THEN
    ALTER TABLE "company_pages" ADD COLUMN "published_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'created_at') THEN
    ALTER TABLE "company_pages" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "company_pages" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'company_pages' AND column_name = 'updated_at') THEN
    ALTER TABLE "company_pages" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "company_pages" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tags' AND column_name = 'id') THEN
    ALTER TABLE "tags" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tags' AND column_name = 'name') THEN
    ALTER TABLE "tags" ADD COLUMN "name" VARCHAR(100);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tags' AND column_name = 'color') THEN
    ALTER TABLE "tags" ADD COLUMN "color" VARCHAR(7);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tags' AND column_name = 'company_id') THEN
    ALTER TABLE "tags" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tags' AND column_name = 'created_at') THEN
    ALTER TABLE "tags" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "tags" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tags' AND column_name = 'id') THEN
    ALTER TABLE "contact_tags" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tags' AND column_name = 'contact_id') THEN
    ALTER TABLE "contact_tags" ADD COLUMN "contact_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contact_tags' AND column_name = 'tag_id') THEN
    ALTER TABLE "contact_tags" ADD COLUMN "tag_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'id') THEN
    ALTER TABLE "sessions" ADD COLUMN "id" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'user_id') THEN
    ALTER TABLE "sessions" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'expires_at') THEN
    ALTER TABLE "sessions" ADD COLUMN "expires_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'created_at') THEN
    ALTER TABLE "sessions" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "sessions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'id') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'deal_id') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "deal_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'title') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "title" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'order_num') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "order_num" integer;
    ALTER TABLE "deal_checklists" ALTER COLUMN "order_num" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_checklists" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklists' AND column_name = 'updated_at') THEN
    ALTER TABLE "deal_checklists" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "deal_checklists" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'id') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'checklist_id') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "checklist_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'text') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "text" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'is_completed') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "is_completed" boolean;
    ALTER TABLE "deal_checklist_items" ALTER COLUMN "is_completed" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'order_num') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "order_num" integer;
    ALTER TABLE "deal_checklist_items" ALTER COLUMN "order_num" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'completed_at') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "completed_at" timestamp without time zone;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'completed_by') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "completed_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_checklist_items" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_checklist_items' AND column_name = 'updated_at') THEN
    ALTER TABLE "deal_checklist_items" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "deal_checklist_items" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'id') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'deal_id') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "deal_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'user_id') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "user_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'comment') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "comment" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_comments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_comments' AND column_name = 'updated_at') THEN
    ALTER TABLE "deal_comments" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "deal_comments" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'id') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'deal_id') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "deal_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'uploaded_by') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "uploaded_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'filename') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "filename" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'file_url') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "file_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'file_size') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "file_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'mime_type') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "mime_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_attachments' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_attachments" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_attachments" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'id') THEN
    ALTER TABLE "pipelines" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'company_id') THEN
    ALTER TABLE "pipelines" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'name') THEN
    ALTER TABLE "pipelines" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'description') THEN
    ALTER TABLE "pipelines" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'is_default') THEN
    ALTER TABLE "pipelines" ADD COLUMN "is_default" boolean;
    ALTER TABLE "pipelines" ALTER COLUMN "is_default" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'created_at') THEN
    ALTER TABLE "pipelines" ADD COLUMN "created_at" timestamp with time zone;
    ALTER TABLE "pipelines" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pipelines' AND column_name = 'updated_at') THEN
    ALTER TABLE "pipelines" ADD COLUMN "updated_at" timestamp with time zone;
    ALTER TABLE "pipelines" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'id') THEN
    ALTER TABLE "properties" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'company_id') THEN
    ALTER TABLE "properties" ADD COLUMN "company_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'name') THEN
    ALTER TABLE "properties" ADD COLUMN "name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'type') THEN
    ALTER TABLE "properties" ADD COLUMN "type" text;
    ALTER TABLE "properties" ALTER COLUMN "type" SET DEFAULT 'house'::property_type;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'status') THEN
    ALTER TABLE "properties" ADD COLUMN "status" text;
    ALTER TABLE "properties" ALTER COLUMN "status" SET DEFAULT 'available'::property_status;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'reference_code') THEN
    ALTER TABLE "properties" ADD COLUMN "reference_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'description') THEN
    ALTER TABLE "properties" ADD COLUMN "description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'sales_speech') THEN
    ALTER TABLE "properties" ADD COLUMN "sales_speech" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'quick_description') THEN
    ALTER TABLE "properties" ADD COLUMN "quick_description" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'price') THEN
    ALTER TABLE "properties" ADD COLUMN "price" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'currency') THEN
    ALTER TABLE "properties" ADD COLUMN "currency" text;
    ALTER TABLE "properties" ALTER COLUMN "currency" SET DEFAULT 'USD'::text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'price_per_m2') THEN
    ALTER TABLE "properties" ADD COLUMN "price_per_m2" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'negotiable') THEN
    ALTER TABLE "properties" ADD COLUMN "negotiable" boolean;
    ALTER TABLE "properties" ALTER COLUMN "negotiable" SET DEFAULT true;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'address') THEN
    ALTER TABLE "properties" ADD COLUMN "address" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'city') THEN
    ALTER TABLE "properties" ADD COLUMN "city" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'state') THEN
    ALTER TABLE "properties" ADD COLUMN "state" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'country') THEN
    ALTER TABLE "properties" ADD COLUMN "country" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'zip_code') THEN
    ALTER TABLE "properties" ADD COLUMN "zip_code" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'neighborhood') THEN
    ALTER TABLE "properties" ADD COLUMN "neighborhood" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'latitude') THEN
    ALTER TABLE "properties" ADD COLUMN "latitude" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'longitude') THEN
    ALTER TABLE "properties" ADD COLUMN "longitude" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'bedrooms') THEN
    ALTER TABLE "properties" ADD COLUMN "bedrooms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'bathrooms') THEN
    ALTER TABLE "properties" ADD COLUMN "bathrooms" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'half_bathrooms') THEN
    ALTER TABLE "properties" ADD COLUMN "half_bathrooms" integer;
    ALTER TABLE "properties" ALTER COLUMN "half_bathrooms" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'parking_spaces') THEN
    ALTER TABLE "properties" ADD COLUMN "parking_spaces" integer;
    ALTER TABLE "properties" ALTER COLUMN "parking_spaces" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'area_m2') THEN
    ALTER TABLE "properties" ADD COLUMN "area_m2" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'area_ft2') THEN
    ALTER TABLE "properties" ADD COLUMN "area_ft2" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'lot_size_m2') THEN
    ALTER TABLE "properties" ADD COLUMN "lot_size_m2" numeric;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'construction_year') THEN
    ALTER TABLE "properties" ADD COLUMN "construction_year" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'floors') THEN
    ALTER TABLE "properties" ADD COLUMN "floors" integer;
    ALTER TABLE "properties" ALTER COLUMN "floors" SET DEFAULT 1;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'features') THEN
    ALTER TABLE "properties" ADD COLUMN "features" jsonb;
    ALTER TABLE "properties" ALTER COLUMN "features" SET DEFAULT '{}'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'files') THEN
    ALTER TABLE "properties" ADD COLUMN "files" jsonb;
    ALTER TABLE "properties" ALTER COLUMN "files" SET DEFAULT '[]'::jsonb;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'tags') THEN
    ALTER TABLE "properties" ADD COLUMN "tags" text[];
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'assigned_agent_id') THEN
    ALTER TABLE "properties" ADD COLUMN "assigned_agent_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'created_by') THEN
    ALTER TABLE "properties" ADD COLUMN "created_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'slug') THEN
    ALTER TABLE "properties" ADD COLUMN "slug" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'is_featured') THEN
    ALTER TABLE "properties" ADD COLUMN "is_featured" boolean;
    ALTER TABLE "properties" ALTER COLUMN "is_featured" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'views_count') THEN
    ALTER TABLE "properties" ADD COLUMN "views_count" integer;
    ALTER TABLE "properties" ALTER COLUMN "views_count" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'created_at') THEN
    ALTER TABLE "properties" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "properties" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'updated_at') THEN
    ALTER TABLE "properties" ADD COLUMN "updated_at" timestamp without time zone;
    ALTER TABLE "properties" ALTER COLUMN "updated_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_properties' AND column_name = 'id') THEN
    CREATE SEQUENCE IF NOT EXISTS deal_properties_id_seq;
    ALTER TABLE "deal_properties" ADD COLUMN "id" integer NOT NULL DEFAULT nextval('deal_properties_id_seq'::regclass);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_properties' AND column_name = 'deal_id') THEN
    ALTER TABLE "deal_properties" ADD COLUMN "deal_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_properties' AND column_name = 'property_id') THEN
    ALTER TABLE "deal_properties" ADD COLUMN "property_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deal_properties' AND column_name = 'created_at') THEN
    ALTER TABLE "deal_properties" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "deal_properties" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'id') THEN
    ALTER TABLE "property_media" ADD COLUMN "id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'property_id') THEN
    ALTER TABLE "property_media" ADD COLUMN "property_id" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'media_type') THEN
    ALTER TABLE "property_media" ADD COLUMN "media_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'file_url') THEN
    ALTER TABLE "property_media" ADD COLUMN "file_url" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'file_name') THEN
    ALTER TABLE "property_media" ADD COLUMN "file_name" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'file_size') THEN
    ALTER TABLE "property_media" ADD COLUMN "file_size" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'mime_type') THEN
    ALTER TABLE "property_media" ADD COLUMN "mime_type" text;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'order_num') THEN
    ALTER TABLE "property_media" ADD COLUMN "order_num" integer;
    ALTER TABLE "property_media" ALTER COLUMN "order_num" SET DEFAULT 0;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'is_flyer') THEN
    ALTER TABLE "property_media" ADD COLUMN "is_flyer" boolean;
    ALTER TABLE "property_media" ALTER COLUMN "is_flyer" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'is_primary') THEN
    ALTER TABLE "property_media" ADD COLUMN "is_primary" boolean;
    ALTER TABLE "property_media" ALTER COLUMN "is_primary" SET DEFAULT false;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'uploaded_by') THEN
    ALTER TABLE "property_media" ADD COLUMN "uploaded_by" integer;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'property_media' AND column_name = 'created_at') THEN
    ALTER TABLE "property_media" ADD COLUMN "created_at" timestamp without time zone;
    ALTER TABLE "property_media" ALTER COLUMN "created_at" SET DEFAULT now();
  END IF;
END $$;
