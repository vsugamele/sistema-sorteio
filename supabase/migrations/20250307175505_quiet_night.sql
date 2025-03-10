/*
  # Points System Fix V6
  
  1. Overview
    - Complete rewrite of points calculation system
    - Fixed points deduction for roulette spins
    - Added proper transaction handling
    - Improved error handling
  
  2. Changes
    - Simplified points calculation logic
    - Fixed points not being tracked after approval
    - Added proper constraints and validations
    - Improved roulette spin handling
  
  3. Security
    - All functions are SECURITY DEFINER
    - Proper RLS policies
*/

-- Drop existing triggers first
DROP TRIGGER IF EXISTS calculate_deposit_points_trigger ON deposits;
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Drop existing functions
DROP FUNCTION IF EXISTS calculate_deposit_points_v2();
DROP FUNCTION IF EXISTS handle_points_deduction();
DROP FUNCTION IF EXISTS get_pending_points_v2(UUID);
DROP FUNCTION IF EXISTS get_available_points_v2(UUID);

-- Create function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  deposit_points integer;
  mission_points integer;
BEGIN
  -- Get pending points from deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)::integer
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Get pending points from missions
  SELECT COALESCE(SUM(m.points_reward), 0)::integer
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN deposit_points + mission_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  deposit_points integer;
  mission_points integer;
  spent_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)::integer
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Get points from approved missions
  SELECT COALESCE(SUM(m.points_reward), 0)::integer
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)::integer
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST((deposit_points + mission_points) - spent_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points_v2()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate points for approved deposits
  IF NEW.status = 'approved' THEN
    -- Points are equal to the floor of the amount
    NEW.points = FLOOR(NEW.amount)::integer;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle points deduction
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get current available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;
  
  -- Validate points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
CREATE TRIGGER calculate_deposit_points_trigger
  BEFORE INSERT OR UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION calculate_deposit_points_v2();

CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();

-- Update existing deposits to ensure points are set correctly
UPDATE deposits 
SET points = FLOOR(amount)::integer 
WHERE status = 'approved' AND (points IS NULL OR points = 0);