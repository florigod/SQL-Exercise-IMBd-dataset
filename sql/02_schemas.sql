CREATE TABLE movies(
    movie_id SERIAL PRIMARY KEY,
    title TEXT UNIQUE NOT NULL,
    imdb_rating NUMERIC(3,1),
    votes BIGINT,
    meta_score NUMERIC(4,1),
    worldwide_gross BIGINT 
);

CREATE TABLE movie_extra_texts( 
    movie_id INT PRIMARY KEY REFERENCES movies(movie_id),
    poster_url TEXT,
    video_url TEXT,
    movie_description TEXT,
    summary TEXT
);

CREATE TABLE tag(
    tag_id SERIAL PRIMARY KEY,
    tag_name TEXT UNIQUE NOT NULL
);

CREATE TABLE movie_tags( 
    movie_id INT REFERENCES movies(movie_id),
    tag_id INT REFERENCES tag(tag_id),
    PRIMARY KEY (movie_id, tag_id)
);


CREATE TABLE people(
    person_id SERIAL PRIMARY KEY,
    person_name TEXT UNIQUE NOT NULL
);


CREATE TABLE writers(
    movie_id INT NOT NULL REFERENCES movies(movie_id),
    writer_person_id INT NOT NULL REFERENCES people(person_id),
    PRIMARY KEY (movie_id, writer_person_id)
);

CREATE TABLE directors(
    movie_id INT PRIMARY KEY REFERENCES movies(movie_id), 
    director_person_id INT REFERENCES people(person_id)
);


CREATE TABLE actors(
    movie_id INT REFERENCES movies(movie_id),
    actor_person_id INT REFERENCES people(person_id),
    PRIMARY KEY (movie_id, actor_person_id)
);
