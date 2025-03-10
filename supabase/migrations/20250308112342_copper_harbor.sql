/*
  # Update Prize Type

  1. Changes
    - Updates the prize "Viagem para o Rio de Janeiro" to "R$ 1.000,00 em compra no Supermercado"
    - Maintains the same value and probability settings
    - Updates existing prizes to reflect the new name

  2. Security
    - No security changes required
    - Existing RLS policies remain unchanged
*/

-- Update existing roulette prize
UPDATE roulette_prizes 
SET name = 'R$ 1.000,00 em compra no Supermercado'
WHERE name = 'Viagem para o Rio de Janeiro'
AND active = true;

-- Update any existing unclaimed prizes to reflect the new name
UPDATE prizes
SET type = 'ticket',
    value = 1000
WHERE value = 1000
  AND type = 'ticket'
  AND NOT claimed;