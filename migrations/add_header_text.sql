-- Migration to add header_text column to Tenant table
ALTER TABLE Tenant ADD COLUMN header_text VARCHAR(255);
-- Add more columns as needed for receipt customization
-- Run this before any INSERTs using header_text
