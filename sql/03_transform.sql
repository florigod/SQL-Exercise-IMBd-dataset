-- 03_transform.sql
-- Transform: populate normalized schema from imdb_raw
BEGIN;

-- populate movies (votes and worldwide_gross cleaning)
INSERT INTO movies (title, imdb_rating, votes, meta_score, worldwide_gross)
SELECT DISTINCT ON (title)
       TRIM(BOTH '"' FROM NULLIF(title, '')) AS title,
       
       -- imdb_rating
       NULLIF(regexp_replace(imdb_rating::text, '[^0-9\.]', '', 'g'), '')::numeric(3,1) AS imdb_rating,
       
       -- votes
       CASE
           WHEN votes IS NULL OR votes::text = '' THEN NULL
           WHEN votes::text ~* '\d+(\.\d+)?\s*[Mm]$' THEN
               CAST(ROUND( (regexp_replace(votes::text, '[^\d.]', '', 'g')::numeric) * 1000000 ) AS BIGINT)
           WHEN votes::text ~* '\d+(\.\d+)?\s*[Kk]$' THEN
               CAST(ROUND( (regexp_replace(votes::text, '[^\d.]', '', 'g')::numeric) * 1000 ) AS BIGINT)
           ELSE
               NULLIF(regexp_replace(votes::text, '[^\d]', '', 'g'), '')::bigint
       END AS votes_clean,
       
       -- meta_score
       NULLIF(regexp_replace(meta_score::text, '[^0-9\.]', '', 'g'), '')::numeric(4,1) AS meta_score,
       
       -- worldwide_gross
       NULLIF(regexp_replace(worldwide_gross::text, '[^\d.]', '', 'g'), '')::numeric(15,2) AS gross_clean
FROM imdb_raw
WHERE title IS NOT NULL AND title <> ''
ORDER BY title, votes_clean DESC;  -- Orders by most votes




-- populate movie_extra_texts (1:1)
INSERT INTO movie_extra_texts (movie_id, poster_url, video_url, movie_description, summary)
SELECT
    m.movie_id,
    r.poster_url,
    r.video_url,
    r.movie_description,
    r.summary
FROM imdb_raw r
JOIN movies m ON TRIM(BOTH '"' FROM NULLIF(r.title, '')) = TRIM(BOTH '"' FROM NULLIF(m.title, '') )
WHERE r.poster_url IS NOT NULL OR r.video_url IS NOT NULL OR r.movie_description IS NOT NULL OR r.summary IS NOT NULL
ON CONFLICT (movie_id) DO NOTHING;

-- populate tag table: split tags and insert distinct tag names
INSERT INTO tag (tag_name)
SELECT DISTINCT TRIM(BOTH '"' FROM TRIM(tag_name)) AS tag_name
FROM imdb_raw r
CROSS JOIN LATERAL regexp_split_to_table(r.tags, '\s*,\s*') AS tag_name
WHERE r.tags IS NOT NULL AND r.tags <> ''
ON CONFLICT (tag_name) DO NOTHING;

-- populate movie_tags relation (ignores duplicates using ON CONFLICT)
INSERT INTO movie_tags (movie_id, tag_id)
SELECT DISTINCT  -- elimina duplicados internos antes del insert
    m.movie_id,
    t.tag_id
FROM imdb_raw r
JOIN movies m ON TRIM(BOTH '"' FROM NULLIF(r.title, '')) = TRIM(BOTH '"' FROM NULLIF(m.title, '') )
CROSS JOIN LATERAL regexp_split_to_table(r.tags, '\s*,\s*') AS raw_tag_name
JOIN tag t ON t.tag_name = TRIM(BOTH '"' FROM raw_tag_name)
WHERE r.tags IS NOT NULL AND r.tags <> ''
ON CONFLICT (movie_id, tag_id) DO NOTHING;



-- populate people (directors, writers, stars) — dedupe using unique constraint on person_name
INSERT INTO people (person_name)
SELECT DISTINCT TRIM(BOTH '"' FROM TRIM(person_name)) AS person_name
FROM (
    SELECT TRIM(BOTH '"' FROM NULLIF(director, '')) AS person_name
    FROM imdb_raw
    WHERE director IS NOT NULL AND director <> ''

    UNION ALL

    SELECT regexp_split_to_table(writers, '\s*,\s*') AS person_name
    FROM imdb_raw
    WHERE writers IS NOT NULL AND writers <> ''

    UNION ALL

    SELECT regexp_split_to_table(stars, '\s*,\s*') AS person_name
    FROM imdb_raw
    WHERE stars IS NOT NULL AND stars <> ''
) s
WHERE person_name IS NOT NULL AND person_name <> ''
ON CONFLICT (person_name) DO NOTHING;

-- populate writers relation (many-to-many). writers table has PK (movie_id, writer_person_id)
INSERT INTO writers (movie_id, writer_person_id)
SELECT DISTINCT
    m.movie_id,
    p.person_id
FROM imdb_raw r
JOIN movies m ON TRIM(BOTH '"' FROM NULLIF(r.title, '')) = TRIM(BOTH '"' FROM NULLIF(m.title, '') )
CROSS JOIN LATERAL regexp_split_to_table(r.writers, '\s*,\s*') AS writer_name
JOIN people p ON p.person_name = TRIM(BOTH '"' FROM writer_name)
WHERE r.writers IS NOT NULL AND r.writers <> ''
ON CONFLICT DO NOTHING;

-- populate directors relation (1:1 table: directors.movie_id PK)
INSERT INTO directors (movie_id, director_person_id)
SELECT
    m.movie_id,
    p.person_id
FROM imdb_raw r
JOIN movies m ON TRIM(BOTH '"' FROM NULLIF(r.title, '')) = TRIM(BOTH '"' FROM NULLIF(m.title, '') )
JOIN people p ON p.person_name = TRIM(BOTH '"' FROM NULLIF(r.director, ''))
WHERE r.director IS NOT NULL AND r.director <> ''
ON CONFLICT (movie_id) DO NOTHING;

-- populate actors relation (many-to-many)
INSERT INTO actors (movie_id, actor_person_id)
SELECT DISTINCT
    m.movie_id,
    p.person_id
FROM imdb_raw r
JOIN movies m ON TRIM(BOTH '"' FROM NULLIF(r.title, '')) = TRIM(BOTH '"' FROM NULLIF(m.title, '') )
CROSS JOIN LATERAL regexp_split_to_table(r.stars, '\s*,\s*') AS star_name
JOIN people p ON p.person_name = TRIM(BOTH '"' FROM star_name)
WHERE r.stars IS NOT NULL AND r.stars <> ''
ON CONFLICT DO NOTHING;

COMMIT;
