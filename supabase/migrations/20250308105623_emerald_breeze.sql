/*
  # Update Roulette Prize Probabilities

  1. Prize Configuration Updates
    Updates the probabilities for all prizes to match new requirements:

    A. Instant Money Prizes (3% total):
      - R$ 20,00: 2% chance
      - R$ 100,00: 1% chance
    
    B. Ticket Prizes (15% total):
      - R$ 1.000,00 ticket: 2% chance
      - Rio de Janeiro trip ticket: 2% chance
      - Smartphone ticket: 2% chance
      - Food baskets ticket: 3% chance
      - Gas tank ticket: 3% chance
      - Beauty day ticket: 3% chance
    
    C. No Prize:
      - "Try again": 82% chance

  2. Notes:
    - All ticket prizes are entries for monthly draws
    - Total probability adds up to 100%
    - Maintains existing prize values and types
*/

-- First, deactivate all existing prizes
UPDATE roulette_prizes SET active = false;

-- Insert new prizes with updated probabilities
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- Instant Money Prizes (3%)
  ('R$ 20,00', 'money', 20.00, 2, true),
  ('R$ 100,00', 'money', 100.00, 1, true),

  -- Ticket Prizes (15%)
  ('Ticket Sorteio R$ 1.000,00', 'ticket', 1000.00, 2, true),
  ('Ticket Viagem Rio de Janeiro', 'ticket', 3000.00, 2, true),
  ('Ticket Celular até R$ 3.000,00', 'ticket', 3000.00, 2, true),
  ('Ticket 5 Cestas Básicas', 'ticket', 1000.00, 3, true),
  ('Ticket Tanque de Gasolina', 'ticket', 500.00, 3, true),
  ('Ticket Dia da Beleza', 'ticket', 300.00, 3, true),

  -- No Prize (82%)
  ('Tente novamente!', 'none', 0.00, 82, true);