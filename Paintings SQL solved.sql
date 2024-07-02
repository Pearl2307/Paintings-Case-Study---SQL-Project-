/* Analyze the Data */
SELECT * FROM artist;
SELECT * FROM canvas_size;
SELECT * FROM image_link;
SELECT * FROM museum
WHERE country = 'USA';
SELECT * FROM museum_hours;
SELECT * FROM product_size;
SELECT * FROM subject;


--1.)  1. Fetch all the paintings which are not displayed on any museums?

SELECT * FROM work
WHERE museum_id is null

 --2. Are there museums without any paintings

select * from museum m
where not exists (select 1 from work w
					 where w.museum_id=m.museum_id);

-- 3. How many paintings have an asking price of more than their regular price?

select * from product_size 
WHERE sale_price > regular_price

-- 4. Identify the paintings whose asking price is less than 50% of its regular price

select * from product_size 
where sale_price < (regular_price * 0.5)

 --5. Which canva size costs the most?

select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id::text=ps.size_id
	where ps.rnk=1;				

--6) Delete duplicate records from work, product_size, subject and image_link tables

delete from work 
	where ctid not in (select min(ctid)
						from work
						group by work_id );

	delete from product_size 
	where ctid not in (select min(ctid)
						from product_size
						group by work_id, size_id );

	delete from subject 
	where ctid not in (select min(ctid)
						from subject
						group by work_id, subject );

	delete from image_link 
	where ctid not in (select min(ctid)
						from image_link
						group by work_id );


--7) Identify the museums with invalid city information in the given dataset

select * from museum
where city ~ '^[0-9]'

--8) Museum_Hours table has 1 invalid entry. Identify it and remove it.

delete from museum_hours 
	where ctid not in (select min(ctid)
						from museum_hours
						group by museum_id, day );

--9) Fetch the top 10 most famous painting subject

SELECT * FROM (select s.subject,count(1) ,rank() over (order by count(1) )from work w 
join subject s on s.work_id = w.work_id
group by s.subject
order by rank desc) 
where rank <= 10
ORDER By rank asc


--10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.

SELECT m.name,m.city 
FROM museum_hours mh1
join museum m on m.museum_id = mh1.museum_id
WHERE day = 'Sunday'
AND exists(SELECT 1 FROM museum_hours mh2
	WHERE mh1.museum_id = mh2.museum_id    
    AND mh2.day = 'Monday')

--11) How many museums are open every single day?

SELECT count (1) FROM (SELECT museum_id,count(museum_id) from museum_hours
group by museum_id
having count(1) =7)


--12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)



SELECT m.name as museum,m.city,m.country,x.no_of_paintings 
FROM (select m.museum_id,count(1) as no_of_paintings , 
	rank() over (order by count(1) desc ) as rnk 
	From work w
    join museum m on m.museum_id = w.museum_id
     group by m.museum_id) x
join museum m on m.museum_id = x.museum_id
where x.rnk<= 5
	order by x.rnk 


--13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select a.artist_id,a.full_name,x.no_of_paintings
FROM

(select a.artist_id,count(1) as no_of_paintings,
	rank() over (order by count(1) desc) rnk
	from work w
    join artist a on a.artist_id = w.artist_id
    group by a.artist_id) x
join artist a on a.artist_id = x.artist_id
where x.rnk <= 5
order by x.rnk 

--14) Display the 3 least popular canva sizes

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id::text = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;

--15.) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day
SELECT * FROM(
SELECT m.name,mh1.day,
to_timestamp(open,'HH:MI AM') as open_date,
	to_timestamp(close,'HH:MI PM') as close_date,
rank() over (order by (to_timestamp(close,'HH:MI PM')  - to_timestamp(open,'HH:MI AM')) ) as rnk

FROM museum_hours mh1 
JOIN museum m on m.museum_id = mh1.museum_id)as x
WHERE x.rnk = 1

--18) Display the country and the city with most no of museums. 
--Output 2 seperate  columns to mention the city and country. If there are multiple value, seperate them  with comma.
WITH cte_country as 
    (SELECT country,count(1),
     rank() over(order by count(1) desc)as rnk
    FROM museum
    GROUP BY country),
 cte_city as 
    (SELECT city,count(1),
     rank() over(order by count(1) desc)as rnk
    FROM museum
    GROUP BY city)

SELECT string_agg(distinct country,',') as country , string_agg(city,',') as city
FROM cte_country
CROSS JOIN cte_city
WHERE cte_country.rnk = 1 AND cte_city.rnk = 1
