/*
  # Configure Roulette Prizes and Probabilities

  1. Prize Configuration
    - Sets up initial prizes with their probabilities
    - Configures both instant prizes and ticket prizes
    - Total probability adds up to 100%

  2. Prize Types
    A. Instant Money Prizes:
      - R$ 20,00 (15% chance)
      - R$ 100,00 (5% chance)
    
    B. Ticket Prizes (Monthly Draw):
      - R$ 1.000,00 (2% chance)
      - Viagem Rio de Janeiro (2% chance)
      - Celular até R$ 3.000,00 (2% chance)
      - 5 Cestas Básicas (3% chance)
      - Tanque de Gasolina (3% chance)
      - Dia da Beleza (3% chance)
    
    C. No Prize:
      - "Tente novamente" (65% chance)

  3. Notes:
    - All ticket prizes become entries for monthly draws
    - Probabilities are carefully balanced for game economy
*/

-- Insert roulette prizes
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- Instant Money Prizes (20%)
  ('R$ 20,00', 'money', 20.00, 15, true),
  ('R$ 100,00', 'money', 100.00, 5, true),

  -- Ticket Prizes (15%)
  ('Ticket Sorteio R$ 1.000,00', 'ticket', 1000.00, 2, true),
  ('Ticket Viagem Rio de Janeiro', 'ticket', 3000.00, 2, true),
  ('Ticket Celular até R$ 3.000,00', 'ticket', 3000.00, 2, true),
  ('Ticket 5 Cestas Básicas', 'ticket', 1000.00, 3, true),
  ('Ticket Tanque de Gasolina', 'ticket', 500.00, 3, true),
  ('Ticket Dia da Beleza', 'ticket', 300.00, 3, true),

  -- No Prize (65%)
  ('Tente novamente!', 'none', 0.00, 65, true);