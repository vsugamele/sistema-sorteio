/*
  # Handle Prize Types Based on Value

  1. Changes
    - Add function to automatically set prize type based on value
    - Add trigger to handle prize type on insert/update
    - Update existing unclaimed prizes to correct type
    - Respect existing trigger that prevents updating claimed prizes

  2. Security
    - No changes to RLS policies needed
*/

-- Function to determine prize type based on value
CREATE OR REPLACE FUNCTION handle_prize_type()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set type if it's a new record or if the prize isn't claimed
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND NOT EXISTS (
    SELECT 1 FROM prizes 
    WHERE id = NEW.id AND claimed = true
  )) THEN
    -- Set type based on value
    NEW.type := CASE
      WHEN NEW.value >= 200 THEN 'ticket'::prize_type
      ELSE 'money'::prize_type
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS set_prize_type ON prizes;

-- Create new trigger for prize type handling
CREATE TRIGGER set_prize_type
  BEFORE INSERT OR UPDATE OF value
  ON prizes
  FOR EACH ROW
  EXECUTE FUNCTION handle_prize_type();

-- Update existing unclaimed prizes to correct type
UPDATE prizes 
SET type = CASE 
  WHEN value >= 200 THEN 'ticket'::prize_type 
  ELSE 'money'::prize_type 
END
WHERE claimed = false;