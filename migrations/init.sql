-- ============================================
-- GANESH DONATION MANAGEMENT - COMPLETE SCHEMA
-- Phase 1 (Core) + Phase 2 (Year) + Phase 3 (Events) + Phase 4 (Subscriptions)
-- ============================================
-- Version: 3.0 - COMPLETE IMPLEMENTATION
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
    religion VARCHAR(50) DEFAULT 'Hindu', -- PHASE 3: Mandal religion (Hindu/Muslim/Buddhist/etc)
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

-- Donation table (with Phase 2: Year + Phase 3: Event linking)
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
    event_id INTEGER, -- PHASE 3: Link to specific event (nullable for general donations)
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

-- ============================================
-- PHASE 3: MULTI-EVENT SUPPORT
-- ============================================

-- EventTypes table (Master list - Super Admin manages)
CREATE TABLE IF NOT EXISTS EventTypes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    name_hindi VARCHAR(255),
    name_marathi VARCHAR(255),
    religion VARCHAR(50) NOT NULL, -- Hindu, Muslim, Buddhist, Sikh, Christian, Jain, General
    icon_url VARCHAR(500),
    color VARCHAR(20) DEFAULT '#4169E1',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default event types
INSERT INTO EventTypes (name, name_hindi, name_marathi, religion, color) VALUES
('Ganesh Chaturthi', 'गणेश चतुर्थी', 'गणेश चतुर्थी', 'Hindu', '#FF9933'),
('Diwali', 'दिवाली', 'दिवाळी', 'Hindu', '#FFD700'),
('Navratri', 'नवरात्री', 'नवरात्री', 'Hindu', '#FF69B4'),
('Ram Navami', 'राम नवमी', 'राम नवमी', 'Hindu', '#FFA500'),
('Shivaji Jayanti', 'शिवाजी जयंती', 'शिवाजी जयंती', 'Hindu', '#FF8C00'),
('Holi', 'होली', 'होळी', 'Hindu', '#FF1493'),
('Eid-ul-Fitr', 'ईद-उल-फितर', 'ईद-उल-फितर', 'Muslim', '#008000'),
('Eid-ul-Adha', 'ईद-उल-अज़हा', 'ईद-उल-अजहा', 'Muslim', '#006400'),
('Ramadan', 'रमजान', 'रमजान', 'Muslim', '#00A86B'),
('Buddha Jayanti', 'बुद्ध जयंती', 'बुद्ध जयंती', 'Buddhist', '#0000FF'),
('Ambedkar Jayanti', 'अम्बेडकर जयंती', 'आंबेडकर जयंती', 'Buddhist', '#0000CD'),
('Guru Nanak Jayanti', 'गुरु नानक जयंती', 'गुरु नानक जयंती', 'Sikh', '#FF8C00'),
('Baisakhi', 'बैसाखी', 'बैसाखी', 'Sikh', '#FFD700'),
('Christmas', 'क्रिसमस', 'ख्रिसमस', 'Christian', '#DC143C'),
('Easter', 'ईस्टर', 'इस्टर', 'Christian', '#FFA500'),
('Mahavir Jayanti', 'महावीर जयंती', 'महावीर जयंती', 'Jain', '#FFD700'),
('Paryushana', 'पर्युषण', 'पर्युषण', 'Jain', '#FF8C00'),
('General Donation', 'सामान्य दान', 'सामान्य देणगी', 'General', '#4169E1')
ON CONFLICT (name) DO NOTHING;

-- OrganizationEvents table (Tenant-specific events)
CREATE TABLE IF NOT EXISTS OrganizationEvents (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    event_type_id INTEGER NOT NULL REFERENCES EventTypes(id),
    event_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_amount DECIMAL(12,2) DEFAULT 0,
    collected_amount DECIMAL(12,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, event_type_id, event_year) -- One event type per year per tenant
);

-- ============================================
-- PHASE 4: SUBSCRIPTION MANAGEMENT
-- ============================================

-- Subscriptions table (Yearly subscriptions for tenants)
CREATE TABLE IF NOT EXISTS Subscriptions (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    subscription_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'PAID', -- PAID, PENDING, EXPIRED
    payment_date DATE,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, subscription_year)
);

-- Create current year subscription for all active tenants
INSERT INTO Subscriptions (tenant_id, subscription_year, start_date, end_date, amount, payment_status)
SELECT 
    id,
    EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    DATE_TRUNC('year', CURRENT_DATE)::DATE,
    (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day')::DATE,
    0,
    'PAID'
FROM Tenant
WHERE status = 'ACTIVE' AND id > 0
ON CONFLICT (tenant_id, subscription_year) DO NOTHING;

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
    
    -- PHASE 3: Add event_id if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='event_id') THEN
        ALTER TABLE Donation ADD COLUMN event_id INTEGER;
    END IF;
    
    -- PHASE 3: Add religion to Tenant if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='religion') THEN
        ALTER TABLE Tenant ADD COLUMN religion VARCHAR(50) DEFAULT 'Hindu';
    END IF;
END $$;

-- PHASE 2: Update existing donations to have year from created_at
UPDATE Donation SET donation_year = EXTRACT(YEAR FROM created_at) 
WHERE donation_year IS NULL AND created_at IS NOT NULL;

-- PHASE 3: Add foreign key for event_id in Donation table (AFTER column is added)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'donation_event_id_fkey'
    ) THEN
        ALTER TABLE Donation ADD CONSTRAINT donation_event_id_fkey 
        FOREIGN KEY (event_id) REFERENCES OrganizationEvents(id) ON DELETE SET NULL;
    END IF;
END $$;

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

-- PHASE 3: Event tracking indexes
CREATE INDEX IF NOT EXISTS idx_donation_event ON Donation(event_id) WHERE event_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_org_events_tenant ON OrganizationEvents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_events_tenant_year ON OrganizationEvents(tenant_id, event_year);
CREATE INDEX IF NOT EXISTS idx_event_types_religion ON EventTypes(religion) WHERE is_active = TRUE;

-- PHASE 4: Subscription indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant ON Subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_year ON Subscriptions(subscription_year);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_year ON Subscriptions(tenant_id, subscription_year);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON Subscriptions(payment_status);

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
-- PHASE 3: Event Statistics View
-- ============================================

-- View for event-wise donation statistics
CREATE OR REPLACE VIEW v_event_donation_stats AS
SELECT 
    oe.tenant_id,
    oe.id as event_id,
    oe.event_year,
    et.name as event_name,
    et.name_hindi,
    et.name_marathi,
    et.religion,
    COUNT(d.id) as total_donations,
    COALESCE(SUM(d.amount), 0) as collected_amount,
    oe.target_amount,
    oe.start_date,
    oe.end_date,
    oe.is_active
FROM OrganizationEvents oe
JOIN EventTypes et ON oe.event_type_id = et.id
LEFT JOIN Donation d ON d.event_id = oe.id AND d.payment_status IN ('PAID', 'COMPLETED')
GROUP BY oe.tenant_id, oe.id, oe.event_year, et.name, et.name_hindi, et.name_marathi, 
         et.religion, oe.target_amount, oe.start_date, oe.end_date, oe.is_active;

-- ============================================
-- Migration Complete
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database schema initialized successfully!';
    RAISE NOTICE 'Phase 1: Core donation management ✓';
    RAISE NOTICE 'Phase 2: Year tracking ✓';
    RAISE NOTICE 'Phase 3: Multi-event support ✓';
    RAISE NOTICE 'Phase 4: Subscription management ✓';
    RAISE NOTICE '========================================';
END $$;
