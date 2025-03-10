/*
  # Remove duplicate deposit mission

  1. Changes
    - Remove duplicate "Depósito de R$ 300" mission while keeping one instance
    - Ensures mission data consistency

  2. Notes
    - Only removes exact duplicates with the same title and requirements
    - Preserves user mission relationships by keeping one instance
*/

-- Find and delete duplicate deposit missions while keeping one instance
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