-- Migration: add_expenses.sql
-- Adds the Expense table for tracking mandal/tenant expenses

CREATE TABLE IF NOT EXISTS Expense (
    id            SERIAL PRIMARY KEY,
    tenant_id     INTEGER NOT NULL REFERENCES Tenant(id) ON DELETE CASCADE,
    recorded_by   INTEGER REFERENCES "User"(id) ON DELETE SET NULL,
    amount        NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category      VARCHAR(100) NOT NULL DEFAULT 'GENERAL',
    note          TEXT,
    expense_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expense_tenant    ON Expense(tenant_id);
CREATE INDEX IF NOT EXISTS idx_expense_date      ON Expense(expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_tenant_date ON Expense(tenant_id, expense_date);
