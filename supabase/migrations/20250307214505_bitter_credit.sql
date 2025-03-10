/*
  # Add link column to missions table

  1. Changes
    - Adds a new 'link' column to the missions table
    - Column is optional (nullable)
    - Updates existing Instagram missions with profile link

  2. Security
    - Inherits existing RLS policies
*/

-- Add link column to missions table
ALTER TABLE missions
ADD COLUMN link text;

-- Update Instagram missions with profile link
UPDATE missions 
SET link = 'https://www.instagram.com/laisebotrader/'
WHERE title ILIKE '%@laise%' OR title ILIKE '%instagram%';