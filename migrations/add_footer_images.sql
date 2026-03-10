-- ============================================
-- Migration: Add footer portrait images to Tenant
-- ============================================
-- Purpose:
--   Allow tenant admins to configure two portrait photos in the receipt footer:
--     footer_left_image_url  — politician / reputed person (left side)
--     footer_right_image_url — president / mandal head  (right side)
--
-- These are stored as Cloudinary (or any CDN) URLs, same as logo_url / upi_qr_url.
-- Both columns are optional (NULL = image not configured).
--
-- Safe to run multiple times (uses IF NOT EXISTS check via ALTER ... ADD COLUMN IF NOT EXISTS).
-- ============================================

ALTER TABLE Tenant
    ADD COLUMN IF NOT EXISTS footer_left_image_url  TEXT,
    ADD COLUMN IF NOT EXISTS footer_left_image_name  VARCHAR(255),
    ADD COLUMN IF NOT EXISTS footer_right_image_url  TEXT,
    ADD COLUMN IF NOT EXISTS footer_right_image_name VARCHAR(255);

-- Verification
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tenant'
  AND column_name IN (
      'footer_left_image_url', 'footer_left_image_name',
      'footer_right_image_url', 'footer_right_image_name'
  )
ORDER BY column_name;
