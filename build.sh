#!/bin/bash
# Render.com build script

echo "Starting build process..."

# Install dependencies
pip install -r requirements.txt

# Run database migrations
echo "Running database migrations..."
python -c "
from app.database import get_connection, release_connection
import os

conn = get_connection()
cur = conn.cursor()

# Read and execute migration file
with open('migrations/001_init.sql', 'r', encoding='utf-8') as f:
    migration_sql = f.read()
    cur.execute(migration_sql)

conn.commit()
cur.close()
release_connection(conn)
print('✅ Database migrations completed')
"

echo "Build completed successfully!"
