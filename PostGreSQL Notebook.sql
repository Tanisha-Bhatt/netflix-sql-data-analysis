DROP TABLE IF EXISTS instagram_influencers;
CREATE TABLE netflix (
    show_id         VARCHAR(10),
    type            VARCHAR(10),
    title           VARCHAR(200),
    director        VARCHAR(300),
    casts           VARCHAR(1000),
    country         VARCHAR(200),
    date_added      VARCHAR(50),
    release_year    INT,
    rating          VARCHAR(10),
    duration        VARCHAR(20),
    listed_in       VARCHAR(300),
    description     TEXT
);
SELECT * FROM netflix LIMIT 5;
SELECT COUNT(*) FROM netflix;

-- Check for NULL values in key columns
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE director IS NULL) AS null_directors,
    COUNT(*) FILTER (WHERE country IS NULL) AS null_countries,
    COUNT(*) FILTER (WHERE rating IS NULL) AS null_ratings,
    COUNT(*) FILTER (WHERE date_added IS NULL) AS null_date_added
FROM netflix;

-- Check for duplicate titles
SELECT title, COUNT(*) AS count
FROM netflix
GROUP BY title
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Trim whitespace from text columns
UPDATE netflix
SET 
    title = TRIM(title),
    director = TRIM(director),
    country = TRIM(country),
    rating = TRIM(rating);

SELECT * FROM netflix;

--To Count Movies vs TV Shows:
SELECT type, COUNT(*) AS total
FROM netflix
GROUP BY type
ORDER BY total DESC;

--All unique ratings on Netflix:
SELECT DISTINCT rating
FROM netflix
ORDER BY rating;

--Content with missing director info:
SELECT COUNT(*) AS missing_directors
FROM netflix
WHERE director IS NULL;

-- All Indian content on Netflix
SELECT title, type, release_year
FROM netflix
WHERE country ILIKE '%India%'
ORDER BY release_year DESC;

-- Keyword Search Using Wildcard Pattern Matching: Titles Containing 'Love
SELECT title, type, country
FROM netflix
WHERE title ILIKE '%love%'
ORDER BY title;

-- Top 10 countries with most Netflix content
SELECT country, COUNT(*) AS total
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total DESC
LIMIT 10;

-- Content added per year (trend)
SELECT EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year_added,
       COUNT(*) AS total
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY year_added
ORDER BY year_added;

-- Most frequent rating per content type:
SELECT type, rating, COUNT(*) AS total
FROM netflix
WHERE rating IS NOT NULL
GROUP BY type, rating
ORDER BY type, total DESC;

-- Top 10 most prolific directors:
SELECT director, COUNT(*) AS total
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total DESC
LIMIT 10;

-- Average movie duration:
SELECT ROUND(AVG(CAST(SPLIT_PART(duration, ' ', 1) AS INT))) AS avg_duration_mins
FROM netflix
WHERE type = 'Movie'
AND duration LIKE '%min%';


-- TV Shows with more than 3 seasons:
SELECT title, duration, country
FROM netflix
WHERE type = 'TV Show'
AND CAST(SPLIT_PART(duration, ' ', 1) AS INT) > 3
ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INT) DESC;

-- Most common genres on Netflix:
SELECT listed_in, COUNT(*) AS total
FROM netflix
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY total DESC
LIMIT 10;

-- Which month sees most content additions:
SELECT TO_CHAR(TO_DATE(date_added, 'Month DD, YYYY'), 'Month') AS month_name,
       COUNT(*) AS total
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY month_name
ORDER BY total DESC;

-- All TV-MA content released after 2018:
SELECT title, type, release_year, country
FROM netflix
WHERE rating = 'TV-MA'
AND release_year > 2018
ORDER BY release_year DESC;

-- Countries producing both Movies AND TV Shows:
SELECT country, COUNT(DISTINCT type) AS content_types
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
HAVING COUNT(DISTINCT type) = 2

-- What % of Netflix is Movies vs TV Shows:
SELECT type,
       COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix), 2) AS percentage
FROM netflix
GROUP BY type
ORDER BY percentage DESC;

-- Find duplicate titles:
SELECT title, COUNT(*) AS count
FROM netflix
GROUP BY title
HAVING COUNT(*) > 1
ORDER BY count DESC
LIMIT 10;

-- Content released same year it was added:
SELECT title, release_year, date_added
FROM netflix
WHERE date_added IS NOT NULL
AND EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) = release_year
ORDER BY release_year DESC;

-- Year over year growth:
SELECT year_added,
       total,
       total - LAG(total) OVER (ORDER BY year_added) AS growth
FROM (
    SELECT EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year_added,
           COUNT(*) AS total
    FROM netflix
    WHERE date_added IS NOT NULL
    GROUP BY year_added
) AS yearly
ORDER BY year_added;

-- Top genre for Movies vs TV Shows separately:
SELECT type, listed_in, COUNT(*) AS total
FROM netflix
WHERE listed_in IS NOT NULL
GROUP BY type, listed_in
ORDER BY type, total DESC
LIMIT 10;

-- Longest and shortest movies:
SELECT title, duration, country
FROM netflix
WHERE type = 'Movie'
AND duration LIKE '%min%'
AND CAST(SPLIT_PART(duration, ' ', 1) AS INT) = (
    SELECT MAX(CAST(SPLIT_PART(duration, ' ', 1) AS INT))
    FROM netflix
    WHERE type = 'Movie' AND duration LIKE '%min%'
)
UNION
SELECT title, duration, country
FROM netflix
WHERE type = 'Movie'
AND duration LIKE '%min%'
AND CAST(SPLIT_PART(duration, ' ', 1) AS INT) = (
    SELECT MIN(CAST(SPLIT_PART(duration, ' ', 1) AS INT))
    FROM netflix
    WHERE type = 'Movie' AND duration LIKE '%min%'
);

-- Content added in last 3 years of dataset:
SELECT title, type, date_added
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= (
    SELECT MAX(TO_DATE(date_added, 'Month DD, YYYY')) - INTERVAL '3 years'
    FROM netflix
    WHERE date_added IS NOT NULL
)
ORDER BY date_added DESC;

--India vs USA comparison:
SELECT 
    country,
    COUNT(*) AS total_titles,
    ROUND(AVG(CAST(SPLIT_PART(duration, ' ', 1) AS INT)) 
        FILTER (WHERE type = 'Movie' AND duration LIKE '%min%')) AS avg_movie_duration,
    COUNT(*) FILTER (WHERE type = 'Movie') AS total_movies,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS total_tvshows
FROM netflix
WHERE country IN ('United States', 'India')
GROUP BY country;

--Rank directors within each country:
SELECT country, director, total_titles,
       RANK() OVER (PARTITION BY country ORDER BY total_titles DESC) AS country_rank
FROM (
    SELECT country, director, COUNT(*) AS total_titles
    FROM netflix
    WHERE director IS NOT NULL AND country IS NOT NULL
    GROUP BY country, director
) AS dir_counts
WHERE country IN ('United States', 'India', 'United Kingdom')
ORDER BY country, country_rank
LIMIT 20;

--Hidden gems — high rating content from small countries:
SELECT country, COUNT(*) AS total,
       COUNT(*) FILTER (WHERE rating = 'TV-MA') AS mature_content
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
HAVING COUNT(*) BETWEEN 10 AND 50
ORDER BY mature_content DESC
LIMIT 10;

--India vs USA vs UK three-way battle:
SELECT 
    CASE 
        WHEN country ILIKE '%United States%' THEN 'USA'
        WHEN country ILIKE '%India%' THEN 'India'
        WHEN country ILIKE '%United Kingdom%' THEN 'UK'
    END AS region,
    COUNT(*) AS total_titles,
    COUNT(*) FILTER (WHERE type = 'Movie') AS movies,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS tv_shows,
    ROUND(AVG(release_year)) AS avg_release_year
FROM netflix
WHERE country ILIKE '%United States%'
   OR country ILIKE '%India%'
   OR country ILIKE '%United Kingdom%'
GROUP BY region
ORDER BY total_titles DESC;