/*
  # Update Prize Type Handling

  1. Changes
    - Add function to determine prize type based on value
    - Add trigger to automatically set prize type on insert/update
    - Update existing unclaimed prizes to correct type

  2. Security
    - Respects existing claimed prize protection
    - Only updates unclaimed prizes
    - Maintains data integrity
*/

-- Function to determine prize type based on value
CREATE OR REPLACE FUNCTION handle_prize_type()
RETURNS TRIGGER AS $$
BEGIN
  -- Prizes >= 200 are handled as tickets
  IF NEW.value >= 200 THEN
    NEW.type := 'ticket';
  ELSE
    NEW.type := 'money';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new/updated prizes
DROP TRIGGER IF EXISTS set_prize_type ON prizes;
CREATE TRIGGER set_prize_type
  BEFORE INSERT OR UPDATE OF value
  ON prizes
  FOR EACH ROW
  EXECUTE FUNCTION handle_prize_type();

-- Update existing unclaimed prizes to correct type
UPDATE prizes 
SET type = CASE 
  WHEN value >= 200 THEN 'ticket'::text 
  ELSE 'money'::text 
END
WHERE claimed = false;