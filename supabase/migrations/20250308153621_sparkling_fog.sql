/*
  # Handle High Value Prizes as Tickets

  1. Changes
    - Add function to automatically set prize type based on value
    - Add trigger to handle prize type on insert
    - Update existing prizes to correct type

  2. Security
    - No changes to RLS policies needed
*/

-- Function to determine prize type based on value
CREATE OR REPLACE FUNCTION determine_prize_type(prize_value numeric)
RETURNS text AS $$
BEGIN
  -- Prizes >= 200 are handled as tickets
  IF prize_value >= 200 THEN
    RETURN 'ticket';
  ELSE
    RETURN 'money';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to set prize type
CREATE OR REPLACE FUNCTION handle_prize_type()
RETURNS TRIGGER AS $$
BEGIN
  -- Only modify type if it wasn't explicitly set
  IF NEW.type IS NULL OR NEW.type = 'money' THEN
    NEW.type := determine_prize_type(NEW.value);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS set_prize_type ON prizes;
CREATE TRIGGER set_prize_type
  BEFORE INSERT OR UPDATE OF value
  ON prizes
  FOR EACH ROW
  EXECUTE FUNCTION handle_prize_type();

-- Update existing prizes to correct type
UPDATE prizes 
SET type = determine_prize_type(value)
WHERE type = 'money' AND value >= 200;