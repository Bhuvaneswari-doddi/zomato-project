drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-09-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-4-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-9-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

select count(userid) from sales;
-- 1.What is the total amount each customer spent on zomato account?
select s.userid, sum(p.price) as Total_Amt_Spent
from sales s
inner join product p
on s.product_id = p.product_id
group by s.userid
order by userid;
;

-- 2. How many days each customer visited Zomato?
select userid, count(distinct(created_date)) as Distinct_days
from sales
group by userid;

-- 3.What was the first product purchased by the each customer

select * 
from (select *, rank() over(partition by userid order by created_date) as rnk from sales) as Source
where rnk = 1;


-- 4. what is the most purchased item on the menu and how many times was it purchased by all customers


select userid,count(product_id) cnt from sales where product_id=
(select top 1 product_id from sales group by product_id order by count(product_id)desc) 
group by userid


-- 5. which item was the most popular for each customer?
select * from (select *, rank() over(partition by userid order by cnt desc) as rnk
from
	(select userid, product_id, count(product_id) as cnt
	from sales
	group by userid, product_id) as a) b
where rnk = 1;

-- 6. which item purchased first by the customer after they become a member
Select * from (select source1.*, rank() over(partition by userid order by created_date) as rnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date
from sales s
inner join goldusers_signup g
on s.userid = g.userid
and  created_date >= gold_signup_date) Source1) source2
where rnk = 1 ;

-- 7. Which item was purchased just before the customer became a member?
select * from
	(select source1.*, rank() over (partition by userid order by created_date desc) rnk 
	from
		(select s.userid, s.created_date, s.product_id, g.gold_signup_date
		from sales s
		inner join goldusers_signup g 
		on s.userid = g.userid
		and created_date < gold_signup_date) as source1) source2
where rnk = 1;


-- 8. what is the total orders and amount spent for each member before they become a member?
select userid, count(created_date) as Order_Purchased, sum(price) as Price 
from(select source1.*, p.price
	from (select s.userid, s.created_date, s.product_id, g.gold_signup_date
		from sales s
		inner join goldusers_signup g 
		on s.userid = g.userid
		and created_date < gold_signup_date) source1
inner join product p 
on p.product_id = source1.product_id) source2
group by userid
order by userid;

/* 9. if buying each product generates points for example 5rs. = 2 zomato point and each product has different purchasing points
 for eg. for p1-5rs-1 zomato point, for p2 -10 rs - 5 zomato point, for p3 - 5 rs - 1 zomato point
 Calculate points collected by each customers and for which product most points have been given till now. */
select userid, sum(total_points) * 2.5 as total_money_earned from
(select e.*, amt/point as total_points 
from (
	select d.*, case when product_id = 1 then 5
	when product_id = 2 then 2 when product_id = 3 then 5 end as point
	from (select c.userid, c.product_id, sum(price) as amt
		from(select s.*, p.price
				from sales s
				inner join product p 
				on s.product_id = p.product_id) C
		group by c.userid, c.product_id) d) e) f 
group by userid;




/* 10. In the first 1 year after a customer joins the gold program (including their join date) irrespective
 of what the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3
 and what was their points earning in the first year? */ 
-- 1 zp = 2 rs so 0.5 zp = 1 rs
select c.*, d.price*0.5 as total_point_earned from
	(select a.userid, a.created_date, a.product_id, b.gold_signup_date
	from sales a inner join goldusers_signup b
	on a.userid = b.userid and created_date>=gold_signup_date and created_date<= dateadd(year,1,gold_signup_date)) c 
inner join product d on c.product_id=d.product_id;


-- 11. Rank all the transaction of the customers
select *, rank() over (partition by userid order by created_date) as rnk 
from sales;
 

/* 12. rank all the transactions for each member wherever they are a zomato gold member for every non gold member transaction 
mark as na. */
select e.*,case when rnk=0 then 'na' else rnk end as rnkk from 
(select c.*,cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as varchar) as rnk from
	(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a 
	LEFT JOIN  goldusers_signup as b on a.userid = b.userid AND created_date >= gold_signup_date)c)e;