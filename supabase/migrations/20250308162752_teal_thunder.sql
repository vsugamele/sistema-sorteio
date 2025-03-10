/*
  # Update Roulette Prize Probabilities

  1. Changes
    - Updates probabilities for existing roulette prizes to better balance rewards
    - Ensures total probability adds up to 100%
    - Maintains existing prize values and types

  2. Prize Distribution
    - No Prize (50%): Most common outcome
    - R$ 20,00 (25%): Common small prize
    - R$ 100,00 (15%): Medium prize
    - R$ 1.000,00 Ticket (10%): Rare ticket for monthly draw
*/

-- Update probabilities for existing prizes
UPDATE roulette_prizes
SET probability = 
  CASE 
    WHEN type = 'none' THEN 50  -- No prize (50%)
    WHEN type = 'money' AND value = 20 THEN 25  -- R$ 20 prize (25%)
    WHEN type = 'money' AND value = 100 THEN 15  -- R$ 100 prize (15%)
    WHEN type = 'ticket' AND value >= 1000 THEN 10  -- Monthly draw ticket (10%)
    ELSE probability  -- Keep other probabilities unchanged
  END
WHERE active = true;