import crypto from 'node:crypto';
import { executeScript, literal } from './db.mjs';

const email = String(process.env.PROVISION_ADMIN_EMAIL || '').trim().toLowerCase();
const password = String(process.env.PROVISION_ADMIN_PASSWORD || '');
if (!email || password.length < 16) throw new Error('Runtime administrator credentials are incomplete');
const salt = crypto.randomBytes(16).toString('hex');
const passwordHash = `scrypt$${salt}$${crypto.scryptSync(password, salt, 32).toString('hex')}`;
executeScript(`
  BEGIN;
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  CREATE TABLE IF NOT EXISTS runtime_users(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'admin', active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  CREATE TABLE IF NOT EXISTS runtime_sessions(
    token_hash TEXT PRIMARY KEY, user_id UUID NOT NULL REFERENCES runtime_users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  CREATE TABLE IF NOT EXISTS runtime_ai_results(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES runtime_users(id) ON DELETE RESTRICT,
    feature TEXT NOT NULL CHECK(feature='movie-library-readiness'), input JSONB NOT NULL,
    provider_request_id TEXT NOT NULL, provider_model TEXT NOT NULL,
    result_text TEXT NOT NULL CHECK(length(result_text)>=40), provider_receipt JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK(provider_receipt->>'requestId'=provider_request_id)
  );
  CREATE TABLE IF NOT EXISTS runtime_ai_attempts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES runtime_users(id) ON DELETE RESTRICT,
    feature TEXT NOT NULL CHECK(feature='movie-library-readiness'), input JSONB NOT NULL,
    requested_model TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('PENDING','SUCCEEDED','FAILED')),
    provider_request_id TEXT, provider_model TEXT, result_id UUID REFERENCES runtime_ai_results(id) ON DELETE RESTRICT,
    error_code TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), completed_at TIMESTAMPTZ,
    CHECK(
      (status='PENDING' AND provider_request_id IS NULL AND provider_model IS NULL AND result_id IS NULL AND error_code IS NULL AND completed_at IS NULL)
      OR (status='SUCCEEDED' AND provider_request_id IS NOT NULL AND provider_model IS NOT NULL AND result_id IS NOT NULL AND error_code IS NULL AND completed_at IS NOT NULL)
      OR (status='FAILED' AND provider_request_id IS NULL AND provider_model IS NULL AND result_id IS NULL AND error_code IS NOT NULL AND completed_at IS NOT NULL)
    )
  );
  CREATE OR REPLACE FUNCTION runtime_ai_append_only() RETURNS trigger AS $$ BEGIN RAISE EXCEPTION 'runtime AI evidence is append-only'; END; $$ LANGUAGE plpgsql;
  DROP TRIGGER IF EXISTS runtime_ai_results_append_only ON runtime_ai_results;
  CREATE TRIGGER runtime_ai_results_append_only BEFORE UPDATE OR DELETE ON runtime_ai_results FOR EACH ROW EXECUTE FUNCTION runtime_ai_append_only();
  CREATE OR REPLACE FUNCTION runtime_ai_attempt_terminal_guard() RETURNS trigger AS $$
  BEGIN
    IF TG_OP='DELETE' THEN RAISE EXCEPTION 'runtime AI attempts are append-only'; END IF;
    IF OLD.status<>'PENDING' OR NEW.status='PENDING' THEN RAISE EXCEPTION 'terminal runtime AI attempts are immutable'; END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.feature IS DISTINCT FROM OLD.feature
       OR NEW.input IS DISTINCT FROM OLD.input OR NEW.requested_model IS DISTINCT FROM OLD.requested_model
       OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN RAISE EXCEPTION 'runtime AI attempt identity is immutable'; END IF;
    RETURN NEW;
  END; $$ LANGUAGE plpgsql;
  DROP TRIGGER IF EXISTS runtime_ai_attempts_terminal_guard ON runtime_ai_attempts;
  CREATE TRIGGER runtime_ai_attempts_terminal_guard BEFORE UPDATE OR DELETE ON runtime_ai_attempts
    FOR EACH ROW EXECUTE FUNCTION runtime_ai_attempt_terminal_guard();
  UPDATE runtime_ai_attempts SET status='FAILED',error_code='INTERRUPTED_BEFORE_TERMINAL',completed_at=NOW() WHERE status='PENDING';
  INSERT INTO runtime_users(email,password_hash,display_name,role,active)
  VALUES(${literal(email)},${literal(passwordHash)},'Runtime Administrator','admin',TRUE)
  ON CONFLICT(email) DO UPDATE SET password_hash=EXCLUDED.password_hash,role='admin',active=TRUE;
  COMMIT;
`);
console.log('Favorite Movies runtime schema and administrator reconciled.');
