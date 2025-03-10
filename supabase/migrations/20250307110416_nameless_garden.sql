/*
  # Add roulette points deduction system

  1. New Functions
    - `deduct_points_from_deposits`: Deducts points from available deposits
    - `handle_roulette_spin`: Handles point deductions for roulette spins

  2. Changes
    - Adds trigger to handle point deductions automatically when spins are created
    - Ensures points are properly deducted from deposits when used

  3. Security
    - Functions are security definer to ensure proper access control
*/

-- Function to deduct points from deposits
CREATE OR REPLACE FUNCTION deduct_points_from_deposits(
  p_user_id uuid,
  p_points_to_deduct integer
) RETURNS boolean
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
  v_remaining_points integer := p_points_to_deduct;
  v_deposit_record record;
BEGIN
  -- Check if user has enough points
  IF (
    SELECT COALESCE(SUM(points), 0)
    FROM deposits
    WHERE user_id = p_user_id
    AND status = 'approved'
  ) < p_points_to_deduct THEN
    RETURN false;
  END IF;

  -- Loop through deposits with available points
  FOR v_deposit_record IN 
    SELECT id, points 
    FROM deposits 
    WHERE user_id = p_user_id 
    AND status = 'approved' 
    AND points > 0 
    ORDER BY created_at ASC
  LOOP
    -- Calculate how many points to deduct from this deposit
    DECLARE
      v_points_to_deduct integer := LEAST(v_remaining_points, v_deposit_record.points);
    BEGIN
      -- Update deposit points
      UPDATE deposits 
      SET points = points - v_points_to_deduct 
      WHERE id = v_deposit_record.id;
      
      -- Update remaining points to deduct
      v_remaining_points := v_remaining_points - v_points_to_deduct;
      
      -- Exit if we've deducted all needed points
      IF v_remaining_points <= 0 THEN
        RETURN true;
      END IF;
    END;
  END LOOP;
  
  RETURN false;
END;
$$;

-- Function to handle roulette spins
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Attempt to deduct points
  IF NOT deduct_points_from_deposits(NEW.user_id, NEW.points_spent) THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for roulette spins
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();