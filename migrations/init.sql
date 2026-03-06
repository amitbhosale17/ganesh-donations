-- ============================================
-- GANESH DONATION MANAGEMENT - CLEAN SCHEMA
-- Phase 1 (Core) + Phase 2 (Year Tracking)
-- ============================================
-- Version: 2.0
-- Date: 2026-03-06
-- Safe to run multiple times (idempotent)
-- ============================================

-- Tenant table (Mandals/Organizations)
CREATE TABLE IF NOT EXISTS Tenant (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    contact_phone VARCHAR(20),
    receipt_prefix VARCHAR(10) DEFAULT 'DN',
    logo_url TEXT,
    upi_qr_url TEXT,
    footer_lines TEXT[],
    footer_text TEXT,
    locale_default VARCHAR(10) DEFAULT 'en',
    president_name VARCHAR(255),
    vice_president_name VARCHAR(255),
    secretary_name VARCHAR(255),
    treasurer_name VARCHAR(255),
    registration_no VARCHAR(100),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User table
CREATE TABLE IF NOT EXISTS "User" (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('SUPERADMIN', 'ADMIN', 'COLLECTOR')),
    password_hash TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Donation table (with Phase 2: Year Tracking)
CREATE TABLE IF NOT EXISTS Donation (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id),
    collector_id INTEGER NOT NULL REFERENCES "User"(id),
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    donor_name VARCHAR(255) NOT NULL,
    donor_phone VARCHAR(20),
    donor_email VARCHAR(255),
    donor_address TEXT,
    donor_pan VARCHAR(20),
    donor_city VARCHAR(100),
    donor_state VARCHAR(100),
    donor_pincode VARCHAR(10),
    amount DECIMAL(10, 2) NOT NULL,
    payment_mode VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'COMPLETED',
    payment_date TIMESTAMP,
    transaction_id VARCHAR(100),
    cheque_number VARCHAR(50),
    bank_name VARCHAR(100),
    utr_number VARCHAR(50),
    category VARCHAR(50) DEFAULT 'GENERAL',
    is_recurring_donor BOOLEAN DEFAULT false,
    additional_notes TEXT,
    collector_notes TEXT,
    notes TEXT,
    donation_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE), -- PHASE 2: Year tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DonationCategory table
CREATE TABLE IF NOT EXISTS DonationCategory (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ReceiptSequence table - for atomic receipt number generation
CREATE TABLE IF NOT EXISTS ReceiptSequence (
    tenant_id INTEGER PRIMARY KEY REFERENCES Tenant(id),
    last_no INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System tenant
INSERT INTO Tenant (id, name, address, receipt_prefix) 
VALUES (0, 'System', 'System', 'SYS')
ON CONFLICT (id) DO NOTHING;

-- SuperAdmin user
INSERT INTO "User" (tenant_id, name, email, role, password_hash, status)
VALUES (0, 'Super Admin', 'superadmin@system.local', 'SUPERADMIN', 'Super@123', 'ACTIVE')
ON CONFLICT (email) DO NOTHING;

-- Fix any existing users without tenant_id or with invalid tenant_id
UPDATE "User" SET tenant_id = 0 WHERE tenant_id IS NULL OR tenant_id NOT IN (SELECT id FROM Tenant);

-- ============================================
-- ALTER TABLE: Add missing columns (safe for existing databases)
-- ============================================

-- Add missing columns to Donation table if they don't exist
DO $$ 
BEGIN
    -- Add is_recurring_donor if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='is_recurring_donor') THEN
        ALTER TABLE Donation ADD COLUMN is_recurring_donor BOOLEAN DEFAULT false;
    END IF;
    
    -- Add additional_notes if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='additional_notes') THEN
        ALTER TABLE Donation ADD COLUMN additional_notes TEXT;
    END IF;
    
    -- Add payment_date if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='payment_date') THEN
        ALTER TABLE Donation ADD COLUMN payment_date TIMESTAMP;
    END IF;
    
    -- Add collector_notes if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='collector_notes') THEN
        ALTER TABLE Donation ADD COLUMN collector_notes TEXT;
    END IF;
    
    -- PHASE 2: Add donation_year if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='donation_year') THEN
        ALTER TABLE Donation ADD COLUMN donation_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE);
    END IF;
END $$;

-- PHASE 2: Update existing donations to have year from created_at
UPDATE Donation SET donation_year = EXTRACT(YEAR FROM created_at) 
WHERE donation_year IS NULL AND created_at IS NOT NULL;

-- ============================================
-- INDEXES for Performance
-- ============================================

-- Basic indexes for foreign keys and common queries
CREATE INDEX IF NOT EXISTS idx_donation_tenant ON Donation(tenant_id);
CREATE INDEX IF NOT EXISTS idx_donation_collector ON Donation(collector_id);
CREATE INDEX IF NOT EXISTS idx_user_tenant ON "User"(tenant_id);
CREATE INDEX IF NOT EXISTS idx_category_tenant ON DonationCategory(tenant_id);

-- PHASE 2: Year tracking indexes
CREATE INDEX IF NOT EXISTS idx_donation_year ON Donation(donation_year);
CREATE INDEX IF NOT EXISTS idx_donation_tenant_year ON Donation(tenant_id, donation_year);

-- Performance indexes for donor search and reports (10x faster queries)
CREATE INDEX IF NOT EXISTS idx_donation_donor_phone ON Donation(donor_phone) WHERE donor_phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_donation_payment_status ON Donation(payment_status);
CREATE INDEX IF NOT EXISTS idx_donation_category ON Donation(category);
CREATE INDEX IF NOT EXISTS idx_donation_date_status ON Donation(created_at, payment_status);
CREATE INDEX IF NOT EXISTS idx_donation_collector_date ON Donation(collector_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donation_is_recurring ON Donation(is_recurring_donor) WHERE is_recurring_donor = true;
CREATE INDEX IF NOT EXISTS idx_donation_payment_date ON Donation(payment_date);

-- ============================================
-- PHASE 2: Yearly Statistics View
-- ============================================

-- View for yearly donation statistics per tenant
CREATE OR REPLACE VIEW v_annual_donation_stats AS
SELECT 
    tenant_id,
    donation_year as year,
    COUNT(*) as total_donations,
    SUM(CASE WHEN payment_status IN ('PAID', 'COMPLETED') THEN amount ELSE 0 END) as total_paid,
    SUM(CASE WHEN payment_status = 'PENDING' THEN amount ELSE 0 END) as total_pending,
    COUNT(DISTINCT collector_id) as active_collectors,
    COUNT(DISTINCT donor_phone) as unique_donors,
    MIN(created_at) as first_donation,
    MAX(created_at) as last_donation
FROM Donation
WHERE donation_year IS NOT NULL
GROUP BY tenant_id, donation_year;

-- ============================================
-- Migration Complete
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database schema initialized successfully!';
    RAISE NOTICE 'Phase 1: Core donation management ✓';
    RAISE NOTICE 'Phase 2: Year tracking ✓';
    RAISE NOTICE '========================================';
END $$;
