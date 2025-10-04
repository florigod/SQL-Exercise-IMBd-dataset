-- Creates table for raw dataset import

CREATE TABLE imdb_raw (
    rank INT PRIMARY KEY,
    title TEXT,
    imdb_rating NUMERIC(3,1), -- 10.0 is possible
    votes TEXT, -- e.g. "371K", "1.1M"
    poster_url TEXT,
    video_url TEXT,
    meta_score NUMERIC(4,1),
    tags TEXT, -- grouped tags, needs normalization
    director TEXT,
    movie_description TEXT,
    writers TEXT, -- grouped
    stars TEXT, -- grouped
    summary TEXT,
    worldwide_gross TEXT -- messy formatting, many nulls
);