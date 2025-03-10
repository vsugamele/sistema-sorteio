/*
  # Update Prize Name

  1. Changes
    - Updates the prize name from "Viagem para o Rio de Janeiro" to "R$ 1.000,00 em compra no Supermercado"
    - Maintains the same value and ticket type
    - Only affects active prizes to preserve history

  2. Security
    - No security changes required
    - Existing RLS policies remain unchanged
*/

-- Update active roulette prize name
UPDATE roulette_prizes 
SET name = 'R$ 1.000,00 em compra no Supermercado'
WHERE name = 'Viagem para o Rio de Janeiro'
  AND active = true;