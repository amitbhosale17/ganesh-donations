-- ============================================
-- SIMPLIFIED DONATION MANAGEMENT SCHEMA
-- Clean, flexible, tenant-based system
-- ============================================
-- Version: 4.0 - SIMPLIFIED ARCHITECTURE
-- Date: 2026-03-07
-- Safe to run multiple times (idempotent)
-- ============================================

-- Drop old tables if restarting fresh
-- DROP TABLE IF EXISTS Donation CASCADE;
-- DROP TABLE IF EXISTS OrganizationEvents CASCADE;
-- DROP TABLE IF EXISTS EventTypes CASCADE;
-- DROP TABLE IF EXISTS Subscriptions CASCADE;
-- DROP TABLE IF EXISTS DonationCategory CASCADE;
-- DROP TABLE IF EXISTS ReceiptSequence CASCADE;
-- DROP TABLE IF EXISTS "User" CASCADE;
-- DROP TABLE IF EXISTS Tenant CASCADE;

-- ============================================
-- CORE TABLES
-- ============================================

-- Tenant table (Mandals/Organizations)
-- Each tenant represents ONE event/community
CREATE TABLE IF NOT EXISTS Tenant (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    
    -- Branding & Customization
    logo_url TEXT,
    qr_code_url TEXT,
    receipt_prefix VARCHAR(10) DEFAULT 'DN',
    header_text VARCHAR(500), -- Custom header for receipts (e.g., "Shri Ganesh Mandal", "Eid Committee")
    footer_text TEXT, -- Custom footer message
    
    -- Office Bearers
    president_name VARCHAR(255),
    vice_president_name VARCHAR(255),
    secretary_name VARCHAR(255),
    treasurer_name VARCHAR(255),
    office_bearers JSONB, -- Flexible storage for additional bearers
    
    -- Legal & Registration
    registration_no VARCHAR(100),
    pan_number VARCHAR(20),
    
    -- Settings
    locale_default VARCHAR(10) DEFAULT 'en',
    status VARCHAR(20) DEFAULT 'ACTIVE',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User table (Super Admin, Tenant Admin, Collectors)
CREATE TABLE IF NOT EXISTS "User" (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER REFERENCES Tenant(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('SUPERADMIN', 'ADMIN', 'COLLECTOR')),
    password_hash TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Donation table (Core feature)
CREATE TABLE IF NOT EXISTS Donation (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    collector_id INTEGER NOT NULL REFERENCES "User"(id),
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    
    -- Donor Information
    donor_name VARCHAR(255) NOT NULL,
    donor_phone VARCHAR(20),
    donor_email VARCHAR(255),
    donor_address TEXT,
    donor_city VARCHAR(100),
    donor_state VARCHAR(100),
    donor_pincode VARCHAR(10),
    donor_pan VARCHAR(20),
    is_recurring_donor BOOLEAN DEFAULT false,
    
    -- Payment Details
    amount DECIMAL(10, 2) NOT NULL,
    payment_mode VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'COMPLETED',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(100),
    cheque_number VARCHAR(50),
    bank_name VARCHAR(100),
    utr_number VARCHAR(50),
    
    -- Categorization
    category VARCHAR(50) DEFAULT 'GENERAL',
    donation_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE), -- Year tracking for subscriptions
    
    -- Notes
    notes TEXT,
    collector_notes TEXT,
    additional_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DonationCategory table (Optional - for tenant-specific categories)
CREATE TABLE IF NOT EXISTS DonationCategory (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, name)
);

-- ReceiptSequence table - for atomic receipt number generation
CREATE TABLE IF NOT EXISTS ReceiptSequence (
    tenant_id INTEGER PRIMARY KEY REFERENCES Tenant(id) ON DELETE CASCADE,
    last_no INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- SUBSCRIPTION MANAGEMENT (Yearly access control)
-- ============================================

-- Subscriptions table (Yearly subscriptions)
-- Each subscription = one year of access for one tenant/event
CREATE TABLE IF NOT EXISTS Subscriptions (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    subscription_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'PENDING', -- PAID, PENDING, EXPIRED
    payment_date DATE,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, subscription_year)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- User indexes
CREATE INDEX IF NOT EXISTS idx_user_tenant ON "User"(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_email ON "User"(email);
CREATE INDEX IF NOT EXISTS idx_user_phone ON "User"(phone);
CREATE INDEX IF NOT EXISTS idx_user_role ON "User"(role);

-- Donation indexes
CREATE INDEX IF NOT EXISTS idx_donation_tenant ON Donation(tenant_id);
CREATE INDEX IF NOT EXISTS idx_donation_collector ON Donation(collector_id);
CREATE INDEX IF NOT EXISTS idx_donation_year ON Donation(donation_year);
CREATE INDEX IF NOT EXISTS idx_donation_receipt ON Donation(receipt_number);
CREATE INDEX IF NOT EXISTS idx_donation_date ON Donation(payment_date);
CREATE INDEX IF NOT EXISTS idx_donation_donor_phone ON Donation(donor_phone);
CREATE INDEX IF NOT EXISTS idx_donation_donor_name ON Donation(donor_name);

-- Subscription indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant ON Subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_year ON Subscriptions(subscription_year);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON Subscriptions(payment_status);

-- Category indexes
CREATE INDEX IF NOT EXISTS idx_category_tenant ON DonationCategory(tenant_id);

-- ============================================
-- INITIAL DATA: Create Super Admin
-- ============================================

-- Create a default tenant for Super Admin
INSERT INTO Tenant (name, address, contact_phone, header_text, footer_text, status)
VALUES (
    'System Administration',
    'N/A',
    'N/A',
    'System Admin',
    'Internal Use Only',
    'ACTIVE'
) ON CONFLICT DO NOTHING;

-- Create Super Admin user
-- Default password: SuperAdmin@123 (hashed with bcrypt)
INSERT INTO "User" (tenant_id, name, email, phone, role, password_hash, status)
SELECT 
    (SELECT id FROM Tenant WHERE name = 'System Administration' LIMIT 1),
    'Super Administrator',
    'superadmin@donation.local',
    '9999999999',
    'SUPERADMIN',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ztP9C0Gs0dXq', -- SuperAdmin@123
    'ACTIVE'
WHERE NOT EXISTS (
    SELECT 1 FROM "User" WHERE role = 'SUPERADMIN' AND email = 'superadmin@donation.local'
);

-- ============================================
-- MIGRATION: Add missing columns (safe for existing databases)
-- ============================================

DO $$ 
BEGIN
    -- Add header_text to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='header_text') THEN
        ALTER TABLE Tenant ADD COLUMN header_text VARCHAR(500);
    END IF;
    
    -- Add qr_code_url to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='qr_code_url') THEN
        ALTER TABLE Tenant ADD COLUMN qr_code_url TEXT;
    END IF;
    
    -- Add office_bearers JSONB to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='office_bearers') THEN
        ALTER TABLE Tenant ADD COLUMN office_bearers JSONB;
    END IF;
    
    -- Add contact_email to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='contact_email') THEN
        ALTER TABLE Tenant ADD COLUMN contact_email VARCHAR(255);
    END IF;
    
    -- Add pan_number to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='pan_number') THEN
        ALTER TABLE Tenant ADD COLUMN pan_number VARCHAR(20);
    END IF;
    
    -- Remove religion column if exists (simplification)
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='tenant' AND column_name='religion') THEN
        ALTER TABLE Tenant DROP COLUMN religion;
    END IF;
    
    -- Remove event_id from Donation if exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='donation' AND column_name='event_id') THEN
        ALTER TABLE Donation DROP COLUMN event_id;
    END IF;
END $$;

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- View: Donation statistics per tenant
CREATE OR REPLACE VIEW vw_tenant_statistics AS
SELECT 
    t.id as tenant_id,
    t.name as tenant_name,
    COUNT(d.id) as total_donations,
    COALESCE(SUM(d.amount), 0) as total_amount,
    COUNT(DISTINCT d.donor_phone) as unique_donors,
    COUNT(DISTINCT d.collector_id) as active_collectors
FROM Tenant t
LEFT JOIN Donation d ON t.id = d.tenant_id
GROUP BY t.id, t.name;

-- View: Yearly donation summary
CREATE OR REPLACE VIEW vw_yearly_donations AS
SELECT 
    tenant_id,
    donation_year,
    COUNT(id) as donation_count,
    SUM(amount) as total_amount,
    AVG(amount) as average_amount,
    MIN(payment_date) as first_donation,
    MAX(payment_date) as last_donation
FROM Donation
GROUP BY tenant_id, donation_year;

-- ============================================
-- COMPLETION
-- ============================================

-- Show summary
DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database initialization complete!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Super Admin Credentials:';
    RAISE NOTICE '  Email: superadmin@donation.local';
    RAISE NOTICE '  Password: SuperAdmin@123';
    RAISE NOTICE '  Phone: 9999999999';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  - Tenant (Organizations/Mandals)';
    RAISE NOTICE '  - User (Super Admin, Admin, Collectors)';
    RAISE NOTICE '  - Donation (Core donation records)';
    RAISE NOTICE '  - DonationCategory (Custom categories)';
    RAISE NOTICE '  - Subscriptions (Yearly access)';
    RAISE NOTICE '  - ReceiptSequence (Receipt numbering)';
    RAISE NOTICE '========================================';
END $$;
