-- NO 1.  Calculate total revenue per year

create table total_revenue_per_year as
select 
	date_part('year', o.order_purchase_timestamp) as year,
	sum(revenue_per_order) as revenue
from (
	select 
		order_id, 
		sum(price+freight_value) as revenue_per_order
	from order_items_dataset
	group by 1
) subq
join order_dataset o on subq.order_id = o.order_id
where o.order_status = 'delivered'
group by 1
order by 1

-- NO 2. Calculate total canceled orders per year

CREATE TABLE total_cancel_order_per_year AS
SELECT
	date_part('year',order_purchase_timestamp) as year,
	COUNT(o.order_id) AS total_cancel
FROM order_dataset as o
WHERE order_status = 'canceled'
GROUP BY 1
ORDER BY 1

-- NO 3. Calculate highest total revenues per product category per year

create table top_product_category_by_revenue_per_year as 
select 
	year, 
	product_category_name, 
	revenue 
from (
	select 
		date_part('year', o.order_purchase_timestamp) as year,
		p.product_category_name,
		sum(oi.price + oi.freight_value) as revenue,
		rank() over(
			partition by date_part('year', o.order_purchase_timestamp) 
	 order by 
	sum(oi.price + oi.freight_value) desc) as rk
	from order_items_dataset oi
	join order_dataset o on o.order_id = oi.order_id
	join product_dataset p on p.product_id = oi.product_id
	where o.order_status = 'delivered'
	group by 1,2
) sq
where rk = 1;

-- NO 4 Calculate highest canceled order per product category per year

create table top_product_category_by_cancel_per_year as 
select 
	year, 
	product_category_name, 
	total_cancel 
from (
	select 
		date_part('year', o.order_purchase_timestamp) as year,
		p.product_category_name,
		count(o.order_id) as total_cancel,
		rank() over(
			partition by date_part('year', o.order_purchase_timestamp) 
	 order by 
	count(o.order_id) desc) as rk
	from order_items_dataset oi
	join order_dataset o on o.order_id = oi.order_id
	join product_dataset p on p.product_id = oi.product_id
	where o.order_status = 'canceled'
	group by 1,2
) sq
where rk = 1;

-- NO 5 Create a new table which contain all the informations above

select 
        tpy.year,
		tpy.product_category_name AS top_product_category_by_revenue,
		tpy.revenue AS category_revenue,
		tr.revenue AS year_total_revenue,
		tcy.product_category_name AS most_canceled_product_category,
		tcy.total_cancel AS category_num_canceled,
		tco.total_cancel AS year_total_num_canceled
from top_product_category_by_revenue_per_year tpy
join total_revenue_per_year tr on tpy.year = tr.year
join top_product_category_by_cancel_per_year tcy on tpy.year = tcy.year
join total_cancel_order_per_year tco on tpy.year = tco.year
