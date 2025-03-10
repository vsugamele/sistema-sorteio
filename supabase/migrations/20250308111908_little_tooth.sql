/*
  # Update Prize Types

  1. Changes
    - Updates roulette prize types to ensure R$ 300,00 prizes are handled as tickets
    - Ensures consistent prize type handling across the system

  2. Security
    - Maintains existing RLS policies
    - No changes to access control
*/

-- Update existing prizes to ensure R$ 300,00 prizes are tickets
UPDATE roulette_prizes
SET type = 'ticket'
WHERE value >= 300 AND type = 'money';

-- Update existing user prizes to ensure consistency
UPDATE prizes 
SET type = 'ticket'
WHERE value >= 300 AND type = 'money';