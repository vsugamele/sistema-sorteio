/*
  # Update Roulette Prize Probabilities

  1. Prize Configuration
    - Update prize probabilities for the roulette game
    - Set up different prize tiers with new probability distribution
    - Total probability adds up to 100%

  2. Prize Types and Probabilities
    - None: No prize (87% chance)
    - Money prizes:
      - R$ 20 (4% chance)
      - R$ 100 (4% chance) 
      - R$ 1.000 (5% chance)

  3. Prize Details
    - Each prize has a name, type, value and probability
    - All prizes are set as active by default
*/

-- Update or insert prize configurations
INSERT INTO roulette_prizes (name, type, value, probability, active)
VALUES
  -- No prize (87%)
  ('Tente novamente', 'none', 0, 87, true),
  
  -- R$ 20 prize (4%)
  ('R$ 20,00 em dinheiro', 'money', 20, 4, true),
  
  -- R$ 100 prize (4%)
  ('R$ 100,00 em dinheiro', 'money', 100, 4, true),
  
  -- R$ 1.000 prize (5%)
  ('R$ 1.000,00 em dinheiro', 'money', 1000, 5, true)
ON CONFLICT (id) DO UPDATE
SET 
  name = EXCLUDED.name,
  type = EXCLUDED.type,
  value = EXCLUDED.value,
  probability = EXCLUDED.probability,
  active = EXCLUDED.active;