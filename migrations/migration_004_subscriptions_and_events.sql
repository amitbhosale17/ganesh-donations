-- Migration 004: Add multi-year subscriptions and multi-event support
-- Run Date: 2026-03-06

-- ============================================
-- PART 1: MULTI-YEAR SUBSCRIPTIONS
-- ============================================

-- Table: Subscriptions (for yearly subscription management)
CREATE TABLE IF NOT EXISTS Subscriptions (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    subscription_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'PAID',
    payment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, subscription_year)
);

-- Add donation_year column to Donation table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='donation_year') THEN
        ALTER TABLE Donation ADD COLUMN donation_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE);
    END IF;
END $$;

-- Update existing donations to have current year
UPDATE Donation SET donation_year = EXTRACT(YEAR FROM created_at) WHERE donation_year IS NULL;

-- Create indexes for fast year queries
CREATE INDEX IF NOT EXISTS idx_donations_year ON Donation(donation_year);
CREATE INDEX IF NOT EXISTS idx_subscriptions_year ON Subscriptions(subscription_year);
CREATE INDEX IF NOT EXISTS idx_donations_tenant_year ON Donation(tenant_id, donation_year);

-- ============================================
-- PART 2: MULTI-EVENT / MULTI-RELIGION SUPPORT
-- ============================================

-- Table: Event Types (master list of all event types)
CREATE TABLE IF NOT EXISTS EventTypes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    name_hindi VARCHAR(255),
    name_marathi VARCHAR(255),
    religion VARCHAR(50), -- Hindu, Muslim, Buddhist, Sikh, Christian, Jain, General
    icon_url VARCHAR(500),
    color VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default event types
INSERT INTO EventTypes (name, name_hindi, name_marathi, religion, color) VALUES
('Ganesh Chaturthi', 'गणेश चतुर्थी', 'गणेश चतुर्थी', 'Hindu', '#FF9933'),
('Diwali', 'दिवाली', 'दिवाळी', 'Hindu', '#FFD700'),
('Navratri', 'नवरात्री', 'नवरात्री', 'Hindu', '#FF69B4'),
('Ram Navami', 'राम नवमी', 'राम नवमी', 'Hindu', '#FFA500'),
('Eid-ul-Fitr', 'ईद-उल-फितर', 'ईद-उल-फितर', 'Muslim', '#008000'),
('Eid-ul-Adha', 'ईद-उल-अज़हा', 'ईद-उल-अजहा', 'Muslim', '#006400'),
('Buddha Jayanti', 'बुद्ध जयंती', 'बुद्ध जयंती', 'Buddhist', '#0000FF'),
('Ambedkar Jayanti', 'अम्बेडकर जयंती', 'आंबेडकर जयंती', 'Buddhist', '#0000CD'),
('Guru Nanak Jayanti', 'गुरु नानक जयंती', 'गुरु नानक जयंती', 'Sikh', '#FF8C00'),
('Christmas', 'क्रिसमस', 'ख्रिसमस', 'Christian', '#DC143C'),
('Mahavir Jayanti', 'महावीर जयंती', 'महावीर जयंती', 'Jain', '#FFD700'),
('General Donation', 'सामान्य दान', 'सामान्य देणगी', 'General', '#4169E1')
ON CONFLICT (name) DO NOTHING;

-- Add religion to Tenant table (Super Admin assigns religion when creating Mandal)
-- This allows Mandals to organize MULTIPLE events of THEIR religion
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='tenant' AND column_name='religion') THEN
        ALTER TABLE Tenant ADD COLUMN religion VARCHAR(50) DEFAULT 'Hindu';
    END IF;
END $$;

-- Set default religion for existing tenants (Hindu)
UPDATE Tenant 
SET religion = 'Hindu'
WHERE religion IS NULL OR religion = '';

-- Add comment explaining the model
COMMENT ON COLUMN Tenant.religion IS 'Mandal religion: Hindu/Muslim/Buddhist/Sikh/Christian/Jain/General. Mandal can create events matching their religion only.';

-- Table: Organization Events (organizations can run multiple events)
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
    UNIQUE(tenant_id, event_type_id, event_year)
);

-- Add event_id to Donation table (link donations to specific events)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='donation' AND column_name='event_id') THEN
        ALTER TABLE Donation ADD COLUMN event_id INTEGER REFERENCES OrganizationEvents(id);
    END IF;
END $$;

-- Create current year subscriptions for all active tenants
INSERT INTO Subscriptions (tenant_id, subscription_year, start_date, end_date, amount, payment_status)
SELECT 
    id,
    EXTRACT(YEAR FROM CURRENT_DATE),
    DATE_TRUNC('year', CURRENT_DATE),
    DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day',
    0,
    'PAID'
FROM Tenant
WHERE status = 'ACTIVE' AND id > 0
ON CONFLICT (tenant_id, subscription_year) DO NOTHING;

-- ============================================
-- PART 3: ENHANCED FILTERS & INDEXES
-- ============================================

-- Add indexes for better filter performance
CREATE INDEX IF NOT EXISTS idx_donations_status ON Donation(payment_status);
CREATE INDEX IF NOT EXISTS idx_donations_method ON Donation(payment_mode);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON Donation(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donations_collector ON Donation(collector_id);
CREATE INDEX IF NOT EXISTS idx_donations_search ON Donation USING gin(to_tsvector('english', donor_name));
CREATE INDEX IF NOT EXISTS idx_donations_tenant_status ON Donation(tenant_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_donations_tenant_date ON Donation(tenant_id, created_at DESC);

-- Composite indexes for common filter combinations
CREATE INDEX IF NOT EXISTS idx_donations_tenant_year_status 
ON Donation(tenant_id, donation_year, payment_status);

CREATE INDEX IF NOT EXISTS idx_donations_tenant_collector_year 
ON Donation(tenant_id, collector_id, donation_year);

-- ============================================
-- PART 4: UTILITY VIEWS
-- ============================================

-- View: Annual donation statistics per tenant
CREATE OR REPLACE VIEW v_annual_donation_stats AS
SELECT 
    tenant_id,
    donation_year,
    COUNT(*) as total_donations,
    SUM(CASE WHEN payment_status = 'PAID' THEN amount ELSE 0 END) as total_paid,
    SUM(CASE WHEN payment_status = 'PENDING' THEN amount ELSE 0 END) as total_pending,
    COUNT(DISTINCT collector_id) as active_collectors,
    COUNT(DISTINCT donor_phone) as unique_donors
FROM Donation
WHERE donation_year IS NOT NULL
GROUP BY tenant_id, donation_year;

-- View: Event-wise donation statistics
CREATE OR REPLACE VIEW v_event_donation_stats AS
SELECT 
    oe.tenant_id,
    oe.id as event_id,
    oe.event_year,
    et.name as event_name,
    et.religion,
    COUNT(d.id) as total_donations,
    COALESCE(SUM(d.amount), 0) as collected_amount,
    oe.target_amount,
    oe.start_date,
    oe.end_date,
    oe.is_active
FROM OrganizationEvents oe
JOIN EventTypes et ON oe.event_type_id = et.id
LEFT JOIN Donation d ON d.event_id = oe.id
GROUP BY oe.tenant_id, oe.id, oe.event_year, et.name, et.religion, 
         oe.target_amount, oe.start_date, oe.end_date, oe.is_active;

-- ============================================
-- PART 5: MIGRATION COMPLETE MESSAGE
-- ============================================

-- Log migration completion
DO $$ 
BEGIN
    RAISE NOTICE 'Migration 004 completed successfully!';
    RAISE NOTICE 'Added: Subscriptions table, EventTypes table, OrganizationEvents table';
    RAISE NOTICE 'Enhanced: Donation table with donation_year and event_id';
    RAISE NOTICE 'Created: Performance indexes and utility views';
END $$;
