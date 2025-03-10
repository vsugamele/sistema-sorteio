/*
  # Configure Roulette Prize Probabilities

  1. Prize Configuration
    - Configure prize probabilities for the roulette game
    - Set up different prize tiers with varying values and chances
    - Ensure total probability adds up to 100%

  2. Prize Types
    - None: No prize (60% chance)
    - Money: Cash prizes
      - R$ 20 (25% chance)
      - R$ 100 (10% chance)
      - R$ 1.000 (5% chance)

  3. Prize Details
    - Each prize has a name, type, value and probability
    - All prizes are set as active by default
*/

-- Insert prize configurations
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- No prize (60%)
  ('Tente novamente', 'none', 0, 60, true),
  
  -- R$ 20 prize (25%)
  ('R$ 20,00 em dinheiro', 'money', 20, 25, true),
  
  -- R$ 100 prize (10%)
  ('R$ 100,00 em dinheiro', 'money', 100, 10, true),
  
  -- R$ 1.000 prize (5%)
  ('R$ 1.000,00 em dinheiro', 'money', 1000, 5, true)
ON CONFLICT (id) DO UPDATE
SET 
  name = EXCLUDED.name,
  type = EXCLUDED.type,
  value = EXCLUDED.value,
  probability = EXCLUDED.probability,
  active = EXCLUDED.active;