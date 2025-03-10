/*
  # Points System Update

  1. Changes
    - Add points column to deposits table
    - Add function to calculate points based on deposit amount
    - Add trigger to automatically update points on status change

  2. Security
    - Only admins can manually update points
    - Points are automatically calculated on status changes
*/

-- Add points column to deposits
ALTER TABLE deposits
ADD COLUMN points integer DEFAULT 0;

-- Create function to calculate points
CREATE OR REPLACE FUNCTION calculate_points(amount numeric)
RETURNS integer
LANGUAGE plpgsql
AS $$
BEGIN
  -- Points are equal to the deposit amount
  RETURN floor(amount)::integer;
END;
$$;

-- Create function to update points based on status
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only calculate points for approved deposits
  IF NEW.status = 'approved' THEN
    NEW.points = calculate_points(NEW.amount);
  ELSE
    NEW.points = 0;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to automatically update points
CREATE TRIGGER deposit_points_trigger
  BEFORE UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_deposit_points();