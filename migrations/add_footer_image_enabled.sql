-- ============================================
-- Migration: Add enabled toggles for footer portrait images
-- ============================================
-- Purpose:
--   Allow tenant admins to show/hide each footer portrait independently
--   without permanently deleting the image.
--
--   footer_left_image_enabled  — controls visibility of left portrait in receipts
--   footer_right_image_enabled — controls visibility of right portrait in receipts
--
-- Both default to TRUE so existing tenants that already have images are unaffected.
-- Safe to run multiple times (uses IF NOT EXISTS).
-- ============================================

ALTER TABLE Tenant
    ADD COLUMN IF NOT EXISTS footer_left_image_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS footer_right_image_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Verification
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'tenant'
  AND column_name IN (
      'footer_left_image_enabled',
      'footer_right_image_enabled'
  )
ORDER BY column_name;
