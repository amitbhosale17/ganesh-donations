-- ============================================
-- Migration: Add footer portrait designations to Tenant
-- ============================================
-- Purpose:
--   Allow tenant admins to configure a designation label under each portrait:
--     footer_left_image_designation  — e.g. "Chief Guest", "MLA", "Patron"
--     footer_right_image_designation — e.g. "President", "Adhyaksha"
--
-- Both columns are optional (NULL = designation not configured).
-- Safe to run multiple times (uses IF NOT EXISTS).
-- ============================================

ALTER TABLE Tenant
    ADD COLUMN IF NOT EXISTS footer_left_image_designation  VARCHAR(255),
    ADD COLUMN IF NOT EXISTS footer_right_image_designation VARCHAR(255);

-- Verification
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tenant'
  AND column_name IN (
      'footer_left_image_designation',
      'footer_right_image_designation'
  )
ORDER BY column_name;
