-- This script creates indexes and views, and defines some useful functions

BEGIN;

--      ========== INDEXES ==========
-- My data set has just 950 rows, so they aren't actually necessary, but instead for practising purposes

-- Most relevant indexes (movie titles, people's names, tags):
CREATE INDEX IF NOT EXISTS idx_movies_title ON movies(title);
CREATE INDEX IF NOT EXISTS idx_people_name ON people(person_name);
CREATE INDEX IF NOT EXISTS idx_tag_name ON tag(tag_name);

-- Usefull indexes (mostly foreign keys for joins):
CREATE INDEX IF NOT EXISTS idx_movie_tags_movie ON movie_tags(movie_id);
CREATE INDEX IF NOT EXISTS idx_movie_tags_tag ON movie_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_writers_movie ON writers(movie_id);
CREATE INDEX IF NOT EXISTS idx_writers_person ON writers(writer_person_id);
CREATE INDEX IF NOT EXISTS idx_actors_movie ON actors(movie_id);
CREATE INDEX IF NOT EXISTS idx_actors_person ON actors(actor_person_id);
CREATE INDEX IF NOT EXISTS idx_directors_movie ON directors(movie_id);


--      ========== VIEW ==========
-- A view combining movie basic info, director name and tags
CREATE OR REPLACE VIEW vw_movie_full AS 
SELECT
    m.movie_id,
    m.title,
    m.imdb_rating,
    m.votes,
    m.meta_score,
    m.worldwide_gross,
    p.person_name AS director_name,
    COALESCE(string_agg(DISTINCT t.tag_name, ', '), '') AS tags -- comma-separated tags
FROM movies m
LEFT JOIN directors d ON d.movie_id = m.movie_id
LEFT JOIN people p ON p.person_id = d.director_person_id
LEFT JOIN movie_tags mt ON mt.movie_id = m.movie_id
LEFT JOIN tag t ON t.tag_id = mt.tag_id
GROUP BY m.movie_id, p.person_name;


--      ========== FUNCTIONS ==========
-- top movies by rating
CREATE OR REPLACE FUNCTION get_top_movies_by_rating(limit_count INT DEFAULT 10)
RETURNS TABLE(movie_id INT, title TEXT, imdb_rating NUMERIC) AS $$
    SELECT movie_id, title, imdb_rating
    FROM movies
    WHERE imdb_rating IS NOT NULL
    ORDER BY imdb_rating DESC NULLS LAST
    LIMIT $1;
$$ LANGUAGE sql STABLE;

-- top movies by votes
CREATE OR REPLACE FUNCTION get_top_movies_by_votes(limit_count INT DEFAULT 10)
RETURNS TABLE(movie_id INT, title TEXT, votes BIGINT) AS $$
    SELECT movie_id, title, votes
    FROM movies
    WHERE votes IS NOT NULL
    ORDER BY votes DESC NULLS LAST
    LIMIT $1;
$$ LANGUAGE sql STABLE;

-- top tags by rating, with minimum count of movies for the tag
CREATE OR REPLACE FUNCTION get_top_tags_by_rating(min_count INT DEFAULT 3,limit_count INT DEFAULT 30)
RETURNS TABLE (
    tag_name TEXT,
    avg_rating NUMERIC,
    n BIGINT
) AS $$
    SELECT t.tag_name,
           AVG(m.imdb_rating) AS avg_rating,
           COUNT(*) AS n
    FROM tag t
    JOIN movie_tags mt ON mt.tag_id = t.tag_id
    JOIN movies m ON m.movie_id = mt.movie_id
    WHERE m.imdb_rating IS NOT NULL
    GROUP BY t.tag_name
    HAVING COUNT(*) >= min_count
    ORDER BY avg_rating DESC, n DESC
    LIMIT limit_count;
$$ LANGUAGE sql STABLE;

-- directors with the most movies
CREATE OR REPLACE FUNCTION get_top_directors(limit_rows INT DEFAULT 20)
RETURNS TABLE (
    director TEXT,
    movies_count BIGINT
) AS $$
    SELECT 
        p.person_name AS director,
        COUNT(*) AS movies_count
    FROM directors d
    JOIN people p ON p.person_id = d.director_person_id
    GROUP BY p.person_name
    ORDER BY movies_count DESC
    LIMIT limit_rows;
$$ LANGUAGE sql STABLE;

-- directors who are also writers
CREATE OR REPLACE FUNCTION get_directors_who_also_write()
RETURNS TABLE (
    person_name TEXT,
    directed_movies TEXT,
    written_movies TEXT
) AS $$
    SELECT DISTINCT 
        p.person_name,
        STRING_AGG(DISTINCT m1.title, ', ') AS directed_movies,
        STRING_AGG(DISTINCT m2.title, ', ') AS written_movies
    FROM people p
    JOIN directors d ON d.director_person_id = p.person_id
    JOIN writers w ON w.writer_person_id = p.person_id
    LEFT JOIN movies m1 ON m1.movie_id = d.movie_id
    LEFT JOIN movies m2 ON m2.movie_id = w.movie_id
    GROUP BY p.person_name;
$$ LANGUAGE sql STABLE;


-- directors who are also stars
CREATE OR REPLACE FUNCTION get_directors_who_also_act()
RETURNS TABLE (
    person_name TEXT,
    directed_movies TEXT,
    acted_movies TEXT
) AS $$
    SELECT DISTINCT 
        p.person_name,
        STRING_AGG(DISTINCT m1.title, ', ') AS directed_movies,
        STRING_AGG(DISTINCT m2.title, ', ') AS acted_movies
    FROM people p
    JOIN directors d ON d.director_person_id = p.person_id
    JOIN actors a ON a.actor_person_id = p.person_id
    LEFT JOIN movies m1 ON m1.movie_id = d.movie_id
    LEFT JOIN movies m2 ON m2.movie_id = a.movie_id
    GROUP BY p.person_name;
$$ LANGUAGE sql STABLE;

-- correlation between imdb rating and meta score
CREATE OR REPLACE FUNCTION get_rating_meta_correlation()
RETURNS NUMERIC AS $$
    SELECT corr(imdb_rating,meta_score)
    FROM movies
    WHERE imdb_rating IS NOT NULL AND meta_score IS NOT NULL;
$$ LANGUAGE sql STABLE;


COMMIT;

