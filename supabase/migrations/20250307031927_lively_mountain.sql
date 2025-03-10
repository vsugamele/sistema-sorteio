/*
  # Add mission points transaction function

  1. New Function
    - `create_mission_points_transaction`: Creates a points transaction when a mission is approved
    - Automatically triggered when a mission status changes to 'approved'

  2. Changes
    - Adds trigger to handle points transactions for approved missions
    - Ensures points are properly credited to user balance
*/

-- Function to create points transaction
CREATE OR REPLACE FUNCTION create_mission_points_transaction()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create transaction when status changes to approved
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    -- Get mission points
    INSERT INTO mission_points_transactions (
      user_id,
      mission_id,
      amount,
      type,
      status,
      created_by,
      description
    )
    SELECT 
      NEW.user_id,
      NEW.mission_id,
      social_missions.points,
      'mission_completed'::point_transaction_type,
      'approved'::mission_status,
      auth.uid(),
      'Mission completed: ' || social_missions.title
    FROM social_missions
    WHERE social_missions.id = NEW.mission_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS mission_points_transaction_trigger ON user_social_missions;
CREATE TRIGGER mission_points_transaction_trigger
  AFTER UPDATE OF status ON user_social_missions
  FOR EACH ROW
  EXECUTE FUNCTION create_mission_points_transaction();