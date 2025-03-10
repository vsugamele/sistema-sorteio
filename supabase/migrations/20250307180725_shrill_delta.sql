/*
  # Fix Roulette Logic

  1. Overview
    - Fixed points calculation and deduction
    - Added proper prize selection logic
    - Added transaction handling
    - Added proper error handling

  2. Changes
    - Added handle_points_deduction function
    - Updated handle_roulette_spin function
    - Added proper prize selection with probability calculation
    - Added points validation

  3. Security
    - All functions are SECURITY DEFINER
    - Added proper error handling
*/

-- Function to handle points deduction
CREATE OR REPLACE FUNCTION handle_points_deduction(user_uuid uuid, points_to_deduct integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deposit_record RECORD;
  points_remaining integer := points_to_deduct;
BEGIN
  -- Get deposits with available points
  FOR deposit_record IN 
    SELECT id, points 
    FROM deposits 
    WHERE user_id = user_uuid 
    AND status = 'approved' 
    AND points > 0 
    ORDER BY created_at ASC
  LOOP
    -- Calculate how many points to deduct from this deposit
    DECLARE
      points_to_remove integer := LEAST(points_remaining, deposit_record.points);
    BEGIN
      -- Update deposit points
      UPDATE deposits 
      SET points = points - points_to_remove
      WHERE id = deposit_record.id;

      points_remaining := points_remaining - points_to_remove;

      -- Exit loop if we've deducted all needed points
      IF points_remaining <= 0 THEN
        EXIT;
      END IF;
    END;
  END LOOP;

  -- Return true if we successfully deducted all points
  RETURN points_remaining <= 0;
END;
$$;

-- Drop existing trigger
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create function to handle roulette spin
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
  total_probability integer;
  random_value integer;
  selected_prize_id uuid;
  points_deducted boolean;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;
  
  -- Validate points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
  END IF;

  -- Deduct points first
  SELECT handle_points_deduction(NEW.user_id, NEW.points_spent) INTO points_deducted;
  
  IF NOT points_deducted THEN
    RAISE EXCEPTION 'Failed to deduct points';
  END IF;

  -- Get total probability
  SELECT SUM(probability)::integer INTO total_probability
  FROM roulette_prizes
  WHERE active = true;

  -- Generate random value
  SELECT floor(random() * total_probability)::integer INTO random_value;

  -- Select prize based on probability
  WITH cumulative_probs AS (
    SELECT 
      id,
      sum(probability) OVER (ORDER BY probability DESC) as cumulative_probability
    FROM roulette_prizes
    WHERE active = true
  )
  SELECT id INTO selected_prize_id
  FROM cumulative_probs
  WHERE cumulative_probability > random_value
  LIMIT 1;

  -- Set the selected prize
  NEW.prize_id = selected_prize_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for roulette spins
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();