"""
App Package Initialization

Purpose:
- This file makes the 'app' directory a Python package
- Allows imports like: from app.config import settings
- Can optionally include package-level initialization code

Why Empty?:
- For simple packages, an empty __init__.py is sufficient
- Just marks the directory as a package
- All actual code is in submodules (config.py, database.py, etc.)

Package Structure:
app/
    __init__.py        <- This file (package marker)
    config.py          <- Configuration settings
    database.py        <- Database connection management
    main.py            <- Flask application setup
    routes/            <- API endpoint definitions
    middleware/        <- Request/response processing
    utils/             <- Helper functions
"""

# Empty file to make this a Python package
# No initialization code needed for this application
