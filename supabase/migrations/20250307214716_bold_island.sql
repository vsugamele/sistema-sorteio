/*
  # Add link column to missions table

  1. Changes
    - Add `link` column to `missions` table to store mission-specific URLs
    - This allows missions to have associated links (e.g., Instagram profile, Telegram group)
    - The column is nullable since not all missions require a link

  2. Security
    - No changes to RLS policies needed
    - Link column inherits existing table permissions
*/

-- Add link column to missions table
ALTER TABLE missions 
ADD COLUMN IF NOT EXISTS link text;

-- Add comment to explain column usage
COMMENT ON COLUMN missions.link IS 'Optional URL associated with the mission (e.g., Instagram profile, Telegram group)';