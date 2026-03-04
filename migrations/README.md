# Database Schema - Single Source of Truth

## ⚠️ IMPORTANT: Single File Approach

**We maintain only ONE database schema file: `init.sql`**

This file contains:
- Complete table definitions
- All columns and constraints
- All indexes (including performance indexes)
- Seed data (SuperAdmin user)

## Why Single File?

✅ **Easy to deploy** - Just run one file on any cloud  
✅ **Crystal clear** - No confusion about which file to run  
✅ **Easy to revert** - One file = one source of truth  
✅ **Cloud portable** - Works on AWS, Azure, Render, anywhere  

## How to Deploy

### Fresh Database Setup
```bash
psql -d your_database -f migrations/init.sql
```

### Existing Database (Add Missing Columns)
The init.sql uses `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`,
so it's safe to run multiple times. It will only add what's missing.

## Schema Overview

### Tables
1. **Tenant** - Organizations (Mandals)
2. **User** - Admin, Collector, SuperAdmin users
3. **Donation** - All donation records
4. **DonationCategory** - Custom categories per tenant

### Performance Indexes
All indexes are included in init.sql:
- `idx_donation_donor_phone` - Fast donor search (10x faster)
- `idx_donation_payment_status` - Fast payment filtering
- `idx_donation_category` - Fast category reports
- `idx_donation_date_status` - Fast date queries
- `idx_donation_collector_date` - Fast collector stats

## Making Changes

**DO NOT** create separate migration files like 001_, 002_, etc.

**Instead:**
1. Update `init.sql` directly
2. Test on dev database
3. Document changes in git commit
4. Deploy by running init.sql on production

## Cloud Deployment

When deploying to a new cloud provider:
1. Create PostgreSQL database
2. Run: `psql -d <db_url> -f migrations/init.sql`
3. Done! ✅

No investigation, no confusion, no multiple files to track.
