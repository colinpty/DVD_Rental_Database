# YouTube Search Function
I have created a Youtube inspired search function for the DVD Rental Database which includes the following features;
- Search Films by their film title and description.
- Allows users to order the search results by either most watched, latest release, and rental rate.
- Gives users the ability to select films based on the release period.
- The users can choose films rating.
- The search also allows the length of the movie to be selected.
- The users can choose which film features they would like to include in their search.

For example, we are searching for the word "Dragon" in the film titles and descriptions. We want to order the results from "Most Watched", we are not interested in any specifying any release period, we want just the films rated "PG13", we don't care about the rental duration or the length of the film, but we want to make sure the film has a Trailer in it's Special Features.  
```
SELECT * FROM search_filmS ('DRAGON','most_watched',NULL,'PG13','NO','NO','Trailers');
```
Below is the code for the search function. 
```
create or replace function search_filmS (
  p_pattern varchar,
  sort_by TEXT,
  release_period TEXT,
  pick_rating TEXT,
  pick_rental_duration TEXT,
  pick_length TEXT,
  pick_features TEXT
) 
	returns table (
		    film_title varchar,
		    film_release_year int,
        film_description TEXT,
        film_cost NUMERIC,
        film_rating TEXT,
        film_rental_duration smallint,
        film_length smallint,
        film_features TEXT
	) 
	language plpgsql
as $$

begin

RETURN QUERY EXECUTE 
' 
WITH cte_most_watched AS (
select 
film.film_id, 
description,
title, 
count (rental_id) AS Most_Watched 
from film 
inner join inventory on inventory.film_id = film.film_id 
inner join rental on inventory.inventory_id = rental.inventory_id 
GROUP BY 1 

), cte_film_ranking AS (
select
	film_id,
	title,
	release_year::integer,
    description,
    rental_rate,
    rating::text,
    rental_duration,
    length,
    special_features::text,
	ts_rank(document_with_weights, plainto_tsquery($1))
from
	film 
where 
	document_with_weights @@ plainto_tsquery($1)
)
SELECT cfr.title, cfr.release_year, cfr.description, cfr.rental_rate, cfr.rating, cfr.rental_duration, cfr.length, cfr.special_features from cte_most_watched cmw 
inner join cte_film_ranking cfr ON cfr.film_id = cmw.film_id 
'
||
 CASE
           WHEN release_period = '20_YEARS' THEN 'WHERE release_year BETWEEN ''2001'' AND ''2021'''
           WHEN release_period = '50_YEARS' THEN 'WHERE release_year BETWEEN ''1971'' AND ''2001'''
           WHEN release_period = '70_YEARS' THEN 'WHERE release_year BETWEEN ''1951'' AND ''1971'''
           WHEN release_period = '100_YEARS' THEN 'WHERE release_year BETWEEN ''1921'' AND ''1951'''
           WHEN release_period = '+100_YEARS' THEN 'WHERE release_year BETWEEN ''1880'' AND ''1921'''
           ELSE 'WHERE release_year BETWEEN ''1880'' AND ''2021'''
       END 
||
 CASE
           WHEN pick_rating = 'PG13' THEN 'AND rating = ''PG-13'''
           WHEN pick_rating = 'R' THEN 'AND rating = ''R'''
           WHEN pick_rating = 'PG' THEN 'AND rating = ''PG'''
           WHEN pick_rating = 'G' THEN 'AND rating = ''G'''
           WHEN pick_rating = 'NC17' THEN 'AND rating = ''NC-17'''
           WHEN pick_rating = 'NO' THEN 'AND rating IN (''PG-13'',''R'',''PG'',''G'',''NC-17'')'
       END 


CASE WHEN pick_rating in ('PG13', 'R', 'PG','G','NC17') THEN
    'and (rating in (''' || pick_rating || '''))'
    ELSE '' END;

||
 CASE
           WHEN pick_rental_duration = '3DAYS' THEN 'AND rental_duration = 3'
           WHEN pick_rental_duration = '4DAYS' THEN 'AND rental_duration = 4'
           WHEN pick_rental_duration = '5DAYS' THEN 'AND rental_duration = 5'
           WHEN pick_rental_duration = '6DAYS' THEN 'AND rental_duration = 6'
           WHEN pick_rental_duration = '7DAYS' THEN 'AND rental_duration = 7'
           WHEN pick_rental_duration = 'NO' THEN 'AND rental_duration BETWEEN 2 AND 8'
       END       
||
 CASE
           WHEN pick_length = 'Short' THEN 'AND length < 40'
           WHEN pick_length = 'Medium' THEN 'AND length <= 100'
           WHEN pick_length = 'Long' THEN 'AND length > 100'
           WHEN pick_length = 'NO' THEN 'AND length > 0'
       END 
||
 CASE
           WHEN pick_features = 'Deleted Scenes' THEN 'AND special_features::text LIKE ''%Deleted Scenes%'''
           WHEN pick_features = 'Commentaries' THEN 'AND special_features::text LIKE ''%Commentaries%'''
           WHEN pick_features = 'Trailers' THEN 'AND special_features::text LIKE ''%Trailers%'''
           WHEN pick_features = 'NO' THEN ''
       END       
||
CASE WHEN sort_by = 'most_watched' THEN  'ORDER BY Most_Watched DESC'
     WHEN sort_by = 'latest_relase' THEN 'ORDER BY release_year DESC'
     WHEN sort_by = 'highTOlow' THEN 'ORDER BY rental_rate DESC'
ELSE 'ORDER BY ts_rank DESC'  END

   USING p_pattern;

end;$$
```
