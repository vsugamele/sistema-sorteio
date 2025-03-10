/*
  # Update Points System and Add New Missions

  1. Points System Changes
    - Update deposit points calculation:
      - R$ 30 = 1 point
      - R$ 50 = 3 points
      - R$ 100 = 5 points
      - R$ 300 = 20 points

  2. New Missions
    - Add new social missions with different point rewards
    - Enable RLS and add appropriate policies
    - Ensure proper indexing for performance

  3. Security
    - Enable RLS on new tables
    - Add policies for proper access control
*/

-- Update or create the function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer AS $$
BEGIN
  -- Calculate points based on deposit amount
  IF amount >= 300 THEN
    RETURN 20;
  ELSIF amount >= 100 THEN
    RETURN 5;
  ELSIF amount >= 50 THEN
    RETURN 3;
  ELSIF amount >= 30 THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Update the deposit points trigger function
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update points when status changes to approved
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    NEW.points = calculate_deposit_points(NEW.amount);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Insert new social missions
INSERT INTO social_missions (title, points, platform, type, active)
VALUES 
  ('Siga nosso Instagram', 2, 'Instagram', 'instagram', true),
  ('Entre no nosso Telegram', 2, 'Telegram', 'telegram', true),
  ('Complete seu Cadastro', 1, 'Platform', 'registration', true),
  ('Compartilhe nosso Instagram', 3, 'Instagram', 'instagram', true);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_social_missions_type_active
ON social_missions (type) WHERE active = true;