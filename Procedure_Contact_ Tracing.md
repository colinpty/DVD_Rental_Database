# Contact Tracing Procedure
I created a procedure which finds all the close contacts of a positive case in the DVD Rental shop shop based on their rental_id. 
Any cusotmer that has RED Alert should Isolate and get tested while a customer with ORANGE Alert should monitor for symptoms.
|ALERT|REPORT|RECOMMENDATION|     
|----|-----|-------|      
|RED|All customers and staff that made any transaction in the store within 2 hours of a positive transaction.|Isolate and get tested| 
|ORANGE|All customers and staff that made any transaction in the store on the day of a positive transaction.|Monitor for symptoms| 

1. We need to create a new table to input the results from the procedure.
```
CREATE SCHEMA REPORTS;

DROP TABLE IF EXISTS REPORTS.POSITIVE_CASES; 
CREATE TABLE REPORTS.POSITIVE_CASES (
    RENTAL_ID INTEGER,
    RENTAL_DATE TIMESTAMP,
    CUSTOMER_ID INTEGER,
    staff_id INTEGER,
    SEVERITY VARCHAR (10),  
    CONSTRAINT POSITIVE_CASES_PK PRIMARY KEY (RENTAL_ID, RENTAL_DATE, CUSTOMER_ID)
) 
```
2. For example, we want to find all the close contacts of the customer with Rental ID "167".
```
CALL GenerateCases(167);

SELECT * FROM REPORTS.POSITIVE_CASES;
```
3. Please see the code below to create the procedure called "GenerateCases".
```
CREATE OR REPLACE PROCEDURE GenerateCases(
    POSITIVE_ID INT
 )
AS $$
DECLARE
    ORANGE_CASE RECORD;
    RED_CASE RECORD;
BEGIN

FOR ORANGE_CASE IN 
    SELECT rental_id, rental_date, customer_id, staff.staff_id, 'ORANGE' AS SEVERITY
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

    LOOP
        INSERT INTO REPORTS.POSITIVE_CASES (RENTAL_ID, RENTAL_DATE, CUSTOMER_ID, STAFF_ID, SEVERITY)
        VALUES (ORANGE_CASE.RENTAL_ID, ORANGE_CASE.RENTAL_DATE, ORANGE_CASE.CUSTOMER_ID, ORANGE_CASE.STAFF_ID, ORANGE_CASE.SEVERITY);
    END LOOP;


FOR RED_CASE IN 

WITH cte_film AS (
SELECT rental_id, rental_date, customer_id, staff.staff_id
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
)
SELECT
rental_id, rental_date, customer_id, staff_id, 'RED' AS SEVERITY
FROM 
    cte_film
WHERE
rental_date BETWEEN (SELECT rental_date::timestamp FROM rental WHERE rental_id=POSITIVE_ID) - (interval '1 HOUR') AND 
(SELECT rental_date::timestamp FROM rental WHERE rental_id=POSITIVE_ID) + (interval '1 HOUR')


LOOP
        UPDATE REPORTS.POSITIVE_CASES 
        SET  RENTAL_ID = RED_CASE.RENTAL_ID,
            RENTAL_DATE = RED_CASE.RENTAL_DATE,
            CUSTOMER_ID = RED_CASE.CUSTOMER_ID,
            STAFF_ID = RED_CASE.STAFF_ID,
            SEVERITY = RED_CASE.SEVERITY
        WHERE RED_CASE.RENTAL_ID = REPORTS.POSITIVE_CASES .RENTAL_ID;

END LOOP;

END;

$$ LANGUAGE PLPGSQL;
```


