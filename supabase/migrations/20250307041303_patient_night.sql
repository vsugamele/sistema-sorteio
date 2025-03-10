/*
  # Remove duplicate deposit mission

  1. Changes
    - Removes duplicate "Depósito de R$ 300" mission while preserving one instance
    - Maintains data integrity by keeping user mission relationships
    - Ensures mission uniqueness in the system

  2. Notes
    - Keeps the oldest mission entry based on created_at timestamp
    - Preserves all associated user data and transactions
*/

WITH duplicates AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY title, type, points_reward, requirements
           ORDER BY created_at ASC
         ) as row_num
  FROM missions
  WHERE title LIKE 'Depósito de R$ 300%'
    AND type = 'deposit'
)
DELETE FROM missions m
USING duplicates d
WHERE m.id = d.id
  AND d.row_num > 1;