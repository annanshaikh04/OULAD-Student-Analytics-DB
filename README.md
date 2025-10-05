<p align="left">
  <a href="https://github.com/annanshaikh04/OULAD-Student-Analytics-DB"><img alt="Repo" src="https://img.shields.io/badge/Repo-MySQL%20ETL-blue"></a>
  <img alt="Python" src="https://img.shields.io/badge/Python-3.10%2B-informational">
  <img alt="Status" src="https://img.shields.io/badge/Status-Active-success">
</p>

<p align="center">
  <img src="docs/ER Diagram_Annan_Rohan_Final Project.png" alt="OULAD Student Analytics DB Banner">
</p>


# OULAD – Student Performance & Engagement Database

A full database project using the Open University Learning Analytics Dataset (OULAD).

## Features
- Normalized schema with constraints, views, roles
- Python ETL scripts for secure, batched loading
- Integrity audits and analytical SQL queries
- Docs include ERD, schema diagrams, project report, and PPT

## Quickstart
### TL;DR
1) Create DB: run `sql/schema.sql` in MySQL.
2) Copy `.env.example` → `.env` and fill DB creds.
3) `pip install -r requirements.txt`
4) `python scripts/insert_data.py`

> Note: `data/STUDENT_VLE.csv` (~423 MB) is not stored in Git (GitHub 100 MB limit).
> Place it at `data/STUDENT_VLE.csv` from your local copy or download it from the link below.

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

## Highlights
- Normalized schema with FKs, indexes, views, roles, and a stored procedure
- Secure ETL (dotenv), batch inserts for large tables
- Integrity audit + fixes (seed missing students)
- Docs included: ERD, schema diagram, full report and PPT

