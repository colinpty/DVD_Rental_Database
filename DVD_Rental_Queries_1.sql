
-- FIND CUSTOMER LOCATIONS

SELECT customer_id, city, country
from 
customer
INNER JOIN address ON customer.address_id = address.address_id
INNER JOIN CITY ON city.city_id = address.city_id
INNER JOIN COUNTRY ON city.country_id = country.country_id
ORDER BY
COUNTRY;


-- FIND STORE LOCATIONS

SELECT store_id, city, country
from 
store
INNER JOIN address ON store.address_id = address.address_id
INNER JOIN CITY ON city.city_id = address.city_id
INNER JOIN COUNTRY ON city.country_id = country.country_id
ORDER BY
city;


-- FIND ALL RENTALS WITHIN A CERTAIN TIME

 SELECT
  rental_id, rental_date, customer_id, staff_id
FROM
  rental
WHERE
      rental_date >= '2005-05-25T08:47:31'
  AND rental_date <  '2005-05-25T10:47:31';

  
