-- Create ReceiptSequence table if it doesn't exist
CREATE TABLE IF NOT EXISTS ReceiptSequence (
    tenant_id INTEGER PRIMARY KEY REFERENCES Tenant(id),
    last_no INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize sequence for existing tenants
INSERT INTO ReceiptSequence (tenant_id, last_no)
SELECT DISTINCT t.id, COALESCE(
    (SELECT COUNT(*) FROM Donation d WHERE d.tenant_id = t.id), 
    0
)
FROM Tenant t
WHERE NOT EXISTS (
    SELECT 1 FROM ReceiptSequence rs WHERE rs.tenant_id = t.id
)
ON CONFLICT (tenant_id) DO NOTHING;

-- Display current state
SELECT t.name, rs.last_no, rs.updated_at 
FROM Tenant t
LEFT JOIN ReceiptSequence rs ON t.id = rs.tenant_id
ORDER BY t.id;
