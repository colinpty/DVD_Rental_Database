
-- GET DATE OF EACH RENTAL WITHOUT TIME

SELECT rental_id, rental_date::timestamp::date
FROM rental;


-- GET ALL RENTALS ON SAME DATE AS 88

SELECT rental_id, rental_date
FROM rental
WHERE rental_date::timestamp::date =
(SELECT rental_date::timestamp::date FROM rental
WHERE rental_id=88);


SELECT rental_id, rental_date, store.store_id
FROM rental
  INNER JOIN staff ON staff.staff_id = rental.staff_id
  INNER JOIN store ON staff.store_id = store.store_id
WHERE rental_date::timestamp::date =
(SELECT rental_date::timestamp::date FROM rental
WHERE rental_id=88);


-- FIND ALL RENTAL SAME DAY + STORE 

SELECT rental_id, rental_date, store.store_id
FROM rental
  INNER JOIN staff ON staff.staff_id = rental.staff_id
  INNER JOIN store ON staff.store_id = store.store_id
WHERE rental_date::timestamp::date =
(SELECT rental_date::timestamp::date FROM rental
WHERE rental_id=33) AND
store.store_id = (select store.store_id from store 
inner join staff on staff.store_id = store.store_id
inner join rental on staff.staff_id = rental.staff_id
where rental_id = 33);

-- FUNCTION

select COVID_DAY_STORE(88);

CREATE OR REPLACE FUNCTION COVID_DAY_STORE(POSITIVE_ID int) RETURNS TABLE(
    rental_id int, rental_date TIMESTAMP, store_id int) AS
$$

SELECT rental_id, rental_date, store.store_id
FROM rental
  INNER JOIN staff ON staff.staff_id = rental.staff_id
  INNER JOIN store ON staff.store_id = store.store_id
WHERE rental_date::timestamp::date =
(SELECT rental_date::timestamp::date FROM rental
WHERE rental_id=POSITIVE_ID) AND
store.store_id = (select store.store_id from store 
inner join staff on staff.store_id = store.store_id
inner join rental on staff.staff_id = rental.staff_id
where rental_id = POSITIVE_ID)

$$ LANGUAGE SQL;


-- CTE FIND RED CASES WITHIN 1 HOUR


WITH cte_film AS (
SELECT rental_id, rental_date, store.store_id
FROM rental
  INNER JOIN staff ON staff.staff_id = rental.staff_id
  INNER JOIN store ON staff.store_id = store.store_id
WHERE rental_date::timestamp::date =
(SELECT rental_date::timestamp::date FROM rental
WHERE rental_id=55) AND
store.store_id = (select store.store_id from store 
inner join staff on staff.store_id = store.store_id
inner join rental on staff.staff_id = rental.staff_id
where rental_id = 55)
)
SELECT
rental_id, rental_date, store_id
FROM 
    cte_film
WHERE
rental_date BETWEEN (SELECT rental_date::timestamp FROM rental WHERE rental_id=55) - (interval '1 HOUR') AND 
(SELECT rental_date::timestamp FROM rental WHERE rental_id=55) + (interval '1 HOUR')
;