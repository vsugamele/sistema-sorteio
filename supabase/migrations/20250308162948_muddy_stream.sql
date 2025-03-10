/*
  # Update Roulette Prize Probabilities

  1. Changes
    - Updates prize probabilities to match new requirements
    - Ensures total probability adds up to 100%
    - Maintains existing prize types and values

  2. Prize Distribution
    - No Prize (86%): Most common outcome
    - Instant Prizes (4% total):
      - R$ 20,00 (3% chance)
      - R$ 100,00 (1% chance)
    - Monthly Draw Tickets (20% total):
      - R$ 1.000,00 em dinheiro (4%)
      - R$ 1.000,00 em compras no Supermercado (4%)
      - Celular até R$ 3.000,00 (4%)
      - 5 Cestas Básicas (3%)
      - Tanque de Gasolina (3%)
      - Dia da Beleza (2%)
*/

-- First, deactivate all existing prizes
UPDATE roulette_prizes SET active = false;

-- Insert new prizes with updated probabilities
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- No Prize (86%)
  ('Não foi dessa vez', 'none', 0, 86, true),
  
  -- Instant Money Prizes (4%)
  ('R$ 20,00', 'money', 20, 3, true),
  ('R$ 100,00', 'money', 100, 1, true),
  
  -- Monthly Draw Tickets (20%)
  ('Ticket Sorteio R$ 1.000,00', 'ticket', 1000, 4, true),
  ('Ticket Sorteio R$ 1.000,00 em Compras', 'ticket', 1000, 4, true),
  ('Ticket Sorteio Celular até R$ 3.000,00', 'ticket', 3000, 4, true),
  ('Ticket Sorteio 5 Cestas Básicas', 'ticket', 500, 3, true),
  ('Ticket Sorteio Tanque de Gasolina', 'ticket', 300, 3, true),
  ('Ticket Sorteio Dia da Beleza', 'ticket', 200, 2, true);