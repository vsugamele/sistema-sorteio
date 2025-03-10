/*
  # Update Instagram Mission Titles

  1. Changes
    - Update mission titles to use @laisebotrader instead of @laise
    - Affects both comment and follow missions
    - Maintains existing points and requirements

  2. Details
    - Updates titles for Instagram-related missions
    - Ensures active missions are properly updated
    - Preserves all other mission attributes
*/

-- Update mission titles for Instagram missions
UPDATE missions
SET title = REPLACE(title, '@laise', '@laisebotrader')
WHERE type = 'instagram'
  AND title LIKE '%@laise%';

-- Update any requirements that might reference the old handle
UPDATE missions
SET requirements = jsonb_set(
  requirements,
  '{instagram_handle}',
  '"laisebotrader"'
)
WHERE type = 'instagram'
  AND requirements->>'instagram_handle' = 'laise';