/*
  # Update Roulette Prize Configuration

  1. Changes
    - Updates all available prizes and their probabilities
    - Ensures total probability adds up to 100%
    - Includes both instant prizes and monthly draw tickets

  2. Prize Distribution
    - No Prize (50%): Most common outcome
    - Instant Prizes:
      - R$ 20,00 (20%): Common small prize
      - R$ 100,00 (10%): Medium prize
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

-- Insert new prizes with correct probabilities
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- No Prize (50%)
  ('Não foi dessa vez', 'none', 0, 50, true),
  
  -- Instant Money Prizes (30%)
  ('R$ 20,00', 'money', 20, 20, true),
  ('R$ 100,00', 'money', 100, 10, true),
  
  -- Monthly Draw Tickets (20%)
  ('Ticket Sorteio R$ 1.000,00', 'ticket', 1000, 4, true),
  ('Ticket Sorteio R$ 1.000,00 em Compras', 'ticket', 1000, 4, true),
  ('Ticket Sorteio Celular até R$ 3.000,00', 'ticket', 3000, 4, true),
  ('Ticket Sorteio 5 Cestas Básicas', 'ticket', 500, 3, true),
  ('Ticket Sorteio Tanque de Gasolina', 'ticket', 300, 3, true),
  ('Ticket Sorteio Dia da Beleza', 'ticket', 200, 2, true);