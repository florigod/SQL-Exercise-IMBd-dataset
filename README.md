# SQL Project – IMDb Mini Dataset

This project is a personal exercise to practice **SQL with PostgreSQL**, using a small subset of IMDb data.  

## Content
- **SQL scripts** organized in stages:  
  - `01_raw_import.sql`: creation of table for raw dataset import from CSV.
  - `02_load_data.sql`: normalized table creation and relationships.  
  - `03_transform.sql`: cleaning and transformations to populate new tables.  
  - `04_indexes_views_funcs.sql`: creation of indexes, views, and functions for more advanced queries.  

- **Dataset** (`data/`) with 14 columns and ~950 rows (≈1MB), of movie-themed data.

## Requirements
- PostgreSQL 15+  
- psql (command line client)

## How to run
1. Create the database:
   ```sql
   CREATE DATABASE imdb;
   ```
2. Run the scripts in order:
    ```sql
    psql -d imdb -f sql/01_raw_import.sql
    psql -d imdb -f sql/02_schemas.sql
    psql -d imdb -f sql/03_transform.sql
    psql -d imdb -f sql/04_indexes_views_funcs.sql
    ````

## 📋 Features included in the 04 SQL script
- **Indexes** on frequently queried fields to improve performance.  
- **Views** to simplify common queries.  
- **Functions** to encapsulate reusable logic. Example:  
    ```sql
    SELECT * FROM get_top_movies_by_rating(10);
    SELECT get_rating_meta_correlation();
    SELECT * FROM get_top_tags_by_rating(5, 50);   
    SELECT * FROM get_top_directors(10);
    ```

## Purpose
This repository is not a finished product, but rather a learning project to practice SQL concepts: schema design, normalization, query optimization, and function creation.