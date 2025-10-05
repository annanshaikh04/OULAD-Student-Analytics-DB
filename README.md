# OULAD – Student Performance & Engagement Database

A full database project using the Open University Learning Analytics Dataset (OULAD).

## Features
- Normalized schema with constraints, views, roles
- Python ETL scripts for secure, batched loading
- Integrity audits and analytical SQL queries
- Docs include ERD, schema diagrams, project report, and PPT

## Quickstart
```bash
# 1) Create virtual environment
python -m venv .venv
source .venv/bin/activate      # (Windows: .venv\Scripts\activate)

# 2) Install requirements
pip install -r requirements.txt

# 3) Configure your database
cp config/.env.example config/.env

# 4) Create schema in MySQL
# Run contents of sql/schema.sql

# 5) Load data
python scripts/insert_data.py