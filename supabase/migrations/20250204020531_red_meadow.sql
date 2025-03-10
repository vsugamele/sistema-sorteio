/*
  # Receipt Cleanup System

  1. Tables
    - deposits_archive: Archive table for old deposits
    - cleanup_logs: Audit logs for cleanup operations
    - cleanup_backups: Temporary backup storage

  2. Functions
    - archive_old_deposits(): Move old deposits to archive
    - cleanup_old_files(): Remove old storage files
    - backup_deposits(): Create backups before deletion
    - verify_data_integrity(): Check data before operations
    - cleanup_expired_backups(): Remove old backups
    - run_cleanup_job(): Main function to run all cleanup tasks
*/

-- Create archive table for old deposits
CREATE TABLE IF NOT EXISTS deposits_archive (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  amount decimal NOT NULL,
  platform text NOT NULL,
  status deposit_status NOT NULL,
  points integer,
  receipt_url text,
  created_at timestamptz NOT NULL,
  archived_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  approved_by uuid REFERENCES auth.users(id),
  rejection_reason text
);

-- Enable RLS on archive table
ALTER TABLE deposits_archive ENABLE ROW LEVEL SECURITY;

-- Create policy for archive access
CREATE POLICY "Admins can access archive"
ON deposits_archive
FOR ALL
TO authenticated
USING (is_admin(auth.uid()));

-- Create audit log table
CREATE TABLE IF NOT EXISTS cleanup_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation text NOT NULL,
  details jsonb NOT NULL,
  status text NOT NULL,
  error_message text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on logs
ALTER TABLE cleanup_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for logs access
CREATE POLICY "Admins can access logs"
ON cleanup_logs
FOR ALL
TO authenticated
USING (is_admin(auth.uid()));

-- Create backup table
CREATE TABLE IF NOT EXISTS cleanup_backups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deposit_id uuid NOT NULL,
  data jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL
);

-- Enable RLS on backups
ALTER TABLE cleanup_backups ENABLE ROW LEVEL SECURITY;

-- Create policy for backups access
CREATE POLICY "Admins can access backups"
ON cleanup_backups
FOR ALL
TO authenticated
USING (is_admin(auth.uid()));

-- Function to verify data integrity
CREATE OR REPLACE FUNCTION verify_data_integrity(deposit_ids uuid[])
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  invalid_records int;
BEGIN
  -- Check for any inconsistencies
  SELECT COUNT(*)
  INTO invalid_records
  FROM deposits d
  WHERE d.id = ANY(deposit_ids)
  AND (
    d.user_id IS NULL OR
    d.amount IS NULL OR
    d.platform IS NULL OR
    d.status IS NULL OR
    d.created_at IS NULL
  );
  
  RETURN invalid_records = 0;
END;
$$;

-- Function to backup deposits before deletion
CREATE OR REPLACE FUNCTION backup_deposits(deposit_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO cleanup_backups (deposit_id, data, expires_at)
  SELECT 
    d.id,
    row_to_json(d)::jsonb,
    now() + interval '15 days'
  FROM deposits d
  WHERE d.id = ANY(deposit_ids);
  
  -- Log backup operation
  INSERT INTO cleanup_logs (operation, details, status)
  VALUES (
    'backup_deposits',
    jsonb_build_object(
      'deposit_ids', deposit_ids,
      'count', array_length(deposit_ids, 1)
    ),
    'success'
  );
EXCEPTION WHEN OTHERS THEN
  INSERT INTO cleanup_logs (operation, details, status, error_message)
  VALUES (
    'backup_deposits',
    jsonb_build_object('deposit_ids', deposit_ids),
    'error',
    SQLERRM
  );
  RAISE;
END;
$$;

-- Function to archive old deposits
CREATE OR REPLACE FUNCTION archive_old_deposits()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_deposit_ids uuid[];
BEGIN
  -- Get IDs of deposits older than 45 days
  SELECT array_agg(id)
  INTO old_deposit_ids
  FROM deposits
  WHERE created_at < now() - interval '45 days';
  
  -- If no old deposits, exit early
  IF old_deposit_ids IS NULL OR array_length(old_deposit_ids, 1) = 0 THEN
    INSERT INTO cleanup_logs (operation, details, status)
    VALUES ('archive_old_deposits', '{"message": "No deposits to archive"}', 'success');
    RETURN;
  END IF;
  
  -- Verify data integrity
  IF NOT verify_data_integrity(old_deposit_ids) THEN
    RAISE EXCEPTION 'Data integrity check failed';
  END IF;
  
  -- Backup deposits
  PERFORM backup_deposits(old_deposit_ids);
  
  -- Move to archive
  WITH moved_deposits AS (
    DELETE FROM deposits
    WHERE id = ANY(old_deposit_ids)
    RETURNING *
  )
  INSERT INTO deposits_archive
  SELECT
    id, user_id, amount, platform, status, points,
    receipt_url, created_at, now(), approved_at,
    approved_by, rejection_reason
  FROM moved_deposits;
  
  -- Log success
  INSERT INTO cleanup_logs (operation, details, status)
  VALUES (
    'archive_old_deposits',
    jsonb_build_object(
      'archived_count', array_length(old_deposit_ids, 1)
    ),
    'success'
  );
EXCEPTION WHEN OTHERS THEN
  INSERT INTO cleanup_logs (operation, details, status, error_message)
  VALUES (
    'archive_old_deposits',
    jsonb_build_object('error_deposit_ids', old_deposit_ids),
    'error',
    SQLERRM
  );
  RAISE;
END;
$$;

-- Function to cleanup old files from storage
CREATE OR REPLACE FUNCTION cleanup_old_files()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_files record;
BEGIN
  -- Get files older than 60 days
  FOR old_files IN (
    SELECT receipt_url
    FROM deposits_archive
    WHERE 
      created_at < now() - interval '60 days'
      AND receipt_url IS NOT NULL
  )
  LOOP
    -- Delete file from storage using storage.delete API
    PERFORM storage.delete(
      'receipts',  -- bucket name
      regexp_replace(old_files.receipt_url, '^.*/receipts/', '')  -- file path
    );
  END LOOP;
  
  -- Log cleanup
  INSERT INTO cleanup_logs (operation, details, status)
  VALUES (
    'cleanup_old_files',
    jsonb_build_object(
      'cleaned_urls', (
        SELECT array_agg(receipt_url)
        FROM deposits_archive
        WHERE created_at < now() - interval '60 days'
      )
    ),
    'success'
  );
EXCEPTION WHEN OTHERS THEN
  INSERT INTO cleanup_logs (operation, details, status, error_message)
  VALUES (
    'cleanup_old_files',
    jsonb_build_object('error', SQLERRM),
    'error',
    SQLERRM
  );
  RAISE;
END;
$$;

-- Function to cleanup expired backups
CREATE OR REPLACE FUNCTION cleanup_expired_backups()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count int;
BEGIN
  WITH deleted AS (
    DELETE FROM cleanup_backups
    WHERE expires_at < now()
    RETURNING id
  )
  SELECT COUNT(*) INTO deleted_count
  FROM deleted;
  
  INSERT INTO cleanup_logs (operation, details, status)
  VALUES (
    'cleanup_expired_backups',
    jsonb_build_object('deleted_count', deleted_count),
    'success'
  );
EXCEPTION WHEN OTHERS THEN
  INSERT INTO cleanup_logs (operation, details, status, error_message)
  VALUES (
    'cleanup_expired_backups',
    jsonb_build_object('error', SQLERRM),
    'error',
    SQLERRM
  );
  RAISE;
END;
$$;

-- Main function to run all cleanup tasks
CREATE OR REPLACE FUNCTION run_cleanup_job()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Archive old deposits
  PERFORM archive_old_deposits();
  -- Cleanup old files
  PERFORM cleanup_old_files();
  -- Cleanup expired backups
  PERFORM cleanup_expired_backups();
  
  -- Log job completion
  INSERT INTO cleanup_logs (operation, details, status)
  VALUES (
    'run_cleanup_job',
    jsonb_build_object(
      'executed_at', now(),
      'next_execution', now() + interval '1 day'
    ),
    'success'
  );
EXCEPTION WHEN OTHERS THEN
  INSERT INTO cleanup_logs (operation, details, status, error_message)
  VALUES (
    'run_cleanup_job',
    jsonb_build_object('error', SQLERRM),
    'error',
    SQLERRM
  );
  RAISE;
END;
$$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_deposits_archive_created_at ON deposits_archive(created_at);
CREATE INDEX IF NOT EXISTS idx_cleanup_logs_created_at ON cleanup_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_cleanup_backups_expires_at ON cleanup_backups(expires_at);