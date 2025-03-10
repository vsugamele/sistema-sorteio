/*
  # Add Ticket Prize Type

  1. Changes
    - Add new prize type for tickets that can be used for bigger prizes
    - Update roulette prizes to include ticket option
    - Ensure existing prizes are preserved

  2. Security
    - Maintains existing RLS policies
    - No changes to access control needed
*/

-- Update or insert roulette prizes
INSERT INTO roulette_prizes (id, name, type, value, probability, active)
VALUES 
  -- Keep existing prizes for smaller amounts
  ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'R$ 20,00', 'money', 20, 15, true),
  ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'R$ 100,00', 'money', 100, 5, true),
  -- Add ticket prize instead of direct R$1000
  ('d290f1ee-6c54-4b01-90e6-d701748f0853', '1 Ticket para Sorteio de R$ 1.000,00', 'ticket', 1000, 1, true),
  -- No prize result
  ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'Tente Novamente', 'none', 0, 79, true)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name,
    type = EXCLUDED.type,
    value = EXCLUDED.value,
    probability = EXCLUDED.probability,
    active = EXCLUDED.active;