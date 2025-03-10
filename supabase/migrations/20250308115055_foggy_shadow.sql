/*
  # Update Roulette Prizes

  1. Changes
    - Update prize values and names to match new structure
    - Replace "Rio de Janeiro trip" with "R$ 1.000,00 em compra no Supermercado"
    - Adjust probabilities for better distribution

  2. Prize Structure
    - Instant Prizes:
      - R$ 20,00 (money)
      - R$ 100,00 (money)
    - Monthly Draw Tickets:
      - R$ 1.000,00 em dinheiro
      - R$ 1.000,00 em compra no Supermercado
      - Celular até R$ 3.000,00
      - 5 Cestas Básicas
      - Tanque de Gasolina
      - Dia da Beleza
*/

-- First deactivate all existing prizes
UPDATE roulette_prizes SET active = false;

-- Insert new prizes with updated values
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- Instant money prizes
  ('Ganhe R$ 20,00', 'money', 20, 15, true),
  ('Ganhe R$ 100,00', 'money', 100, 5, true),
  
  -- Monthly draw tickets
  ('R$ 1.000,00 em dinheiro', 'ticket', 1000, 10, true),
  ('R$ 1.000,00 em compra no Supermercado', 'ticket', 1000, 10, true),
  ('Celular até R$ 3.000,00', 'ticket', 3000, 10, true),
  ('5 Cestas Básicas', 'ticket', 500, 15, true),
  ('Tanque de Gasolina', 'ticket', 300, 15, true),
  ('Dia da Beleza', 'ticket', 200, 15, true),
  
  -- No prize result
  ('Tente novamente', 'none', 0, 5, true);