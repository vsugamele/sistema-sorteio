/*
  # Add points deduction trigger

  1. New Functions
    - `deduct_points_from_deposits`: Deducts points from available deposits
    - `handle_points_transaction`: Handles point transactions and deductions

  2. Changes
    - Adds trigger to handle point deductions automatically when transactions are created
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
  
  -- Return false if we couldn't deduct all points
  RETURN v_remaining_points <= 0;
END;
$$;

-- Function to handle points transactions
CREATE OR REPLACE FUNCTION handle_points_transaction()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only handle points_adjusted transactions
  IF NEW.type = 'points_adjusted' THEN
    -- Attempt to deduct points
    IF NOT deduct_points_from_deposits(NEW.user_id, NEW.amount) THEN
      RAISE EXCEPTION 'Insufficient points available';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for points transactions
DROP TRIGGER IF EXISTS handle_points_transaction_trigger ON mission_points_transactions;
CREATE TRIGGER handle_points_transaction_trigger
  BEFORE INSERT ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_transaction();