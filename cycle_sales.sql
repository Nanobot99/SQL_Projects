create database cycle;
# Imported the CSV files using Import Table Wizard
use cycle;
select * from brands;
select * from categories;
select * from customers;
select * from order_items;
select * from orders;
select * from products;
select * from staffs;
select * from stocks;
select * from stores;

# Who are the top 10 customers by total spend?
select c.customer_id,
       concat(c.first_name, ' ', c.last_name) as customer_name,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as total_spend
from customers c
join orders o on o.customer_id = c.customer_id
join order_items oi on oi.order_id = o.order_id
group by c.customer_id, customer_name
order by total_spend desc
limit 10;

# What is the average order value (AOV) per customer?
select
	customer_id,
    customer_name,
    total_orders,
    total_spend,
    round(total_spend / nullif(total_orders, 0),2) as aov
from(
	select
    c.customer_id,
    concat(c.first_name, ' ', c.last_name) as customer_name,
    count(distinct o.order_id) as total_orders,
    round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount, 0))),2) as total_spend
from customers c
join orders o on o.customer_id = c.customer_id
join order_items oi on oi.order_id = o.order_id
group by c.customer_id, customer_name
) as customers_aov_summary;

# Which city/state has the highest number of active customers?
select c.city, c.state, count(distinct c.customer_id) as active_customers
from customers c
join orders o on o.customer_id = c.customer_id
group by c.city, c.state
order by active_customers desc
limit 1;
   
# What is the total revenue generated in each year/month/quarter?
select extract(year from o.order_date) as year,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from orders o
join order_items oi on oi.order_id = o.order_id
group by year
order by year;

select extract(year from o.order_date) as year,
       extract(month from o.order_date) as month,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from orders o
join order_items oi on oi.order_id = o.order_id
group by year, month
order by year, month;

select extract(year from o.order_date) as year,
       extract(quarter from o.order_date) as quarter,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from orders o
join order_items oi on oi.order_id = o.order_id
group by year, quarter
order by year, quarter;

# Which products generate the highest revenue overall?
select p.product_id, p.product_name,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from products p
join order_items oi on oi.product_id = p.product_id
group by p.product_id, p.product_name
order by revenue desc
limit 20;

# Which stores are top-performing by revenue and order volume?
select s.store_id, s.store_name,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue,
       count(distinct o.order_id) as order_volume
from stores s
join orders o on o.store_id = s.store_id
join order_items oi on oi.order_id = o.order_id
group by s.store_id, s.store_name
order by revenue desc;

# Which categories and brands drive the most sales?
select cat.category_id, cat.category_name,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from categories cat
join products p on p.category_id = cat.category_id
join order_items oi on oi.product_id = p.product_id
group by cat.category_id, cat.category_name
order by revenue desc;

select b.brand_id, b.brand_name,
       round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount,0))),2) as revenue
from brands b
join products p on p.brand_id = b.brand_id
join order_items oi on oi.product_id = p.product_id
group by b.brand_id, b.brand_name
order by revenue desc;

# Which staff member has processed the most orders?
select st.staff_id, concat(st.first_name, ' ', st.last_name) as staff_name,
       count(distinct o.order_id) as orders_processed
from staffs st
join orders o on o.staff_id = st.staff_id
group by st.staff_id, staff_name
order by orders_processed desc
limit 1;

# What is the average order processing time per staff?
select st.staff_id, concat(st.first_name, ' ', st.last_name) as staff_name,
       avg(datediff(o.shipped_date, o.order_date)) as avg_processing_interval
from staffs st
join orders o on o.staff_id = st.staff_id
where o.shipped_date is not null
group by st.staff_id, staff_name
order by avg_processing_interval;

# Which store has the fastest delivery/shipping times?
select s.store_id, s.store_name,
       avg(datediff(o.shipped_date,o.order_date)) as avg_processing_interval
from stores s
join orders o on o.store_id = s.store_id
where o.shipped_date IS NOT NULL
group by s.store_id, s.store_name
order by avg_processing_interval;

# Which staff members are handling the most valuable customers?
select st.staff_id,
       concat(st.first_name, ' ', st.last_name) as staff_name,
       count(distinct case when cv.customer_id is not null then o.customer_id end) as top_customers_handled,
       round(sum(case when cv.customer_id is not null then oi.quantity * oi.list_price * (1 - coalesce(oi.discount, 0)) else 0 end),2) as revenue_from_top_customers
from staffs st
join orders o on o.staff_id = st.staff_id
join order_items oi on oi.order_id = o.order_id
left join (
    select customer_id
    from (
        select c.customer_id,
               round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount, 0))),2) as lifetime_spend
        from customers c
        join orders o on o.customer_id = c.customer_id
        join order_items oi on oi.order_id = o.order_id
        group by c.customer_id
        order by lifetime_spend desc
        limit 100
    ) as top_spenders
) as cv on cv.customer_id = o.customer_id
group by st.staff_id, staff_name
order by revenue_from_top_customers desc;

# Which products are most frequently ordered together ?
select p1.product_id as product_a, p2.product_id as product_b,
       p1.product_name as name_a, p2.product_name as name_b,
       count(*) as times_bought_together
from order_items oi1
join order_items oi2 on oi1.order_id = oi2.order_id and oi1.product_id < oi2.product_id
join products p1 on p1.product_id = oi1.product_id
join products p2 on p2.product_id = oi2.product_id
group by product_a, product_b, name_a, name_b
order by times_bought_together desc
limit 50;

# Identify products that have sales growth for 3 consecutive months.
with monthly_prod as (
  select 
    oi.product_id,
    date_format(o.order_date, '%Y-%m-01') as month_start,
    round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount, 0))),2) as revenue
  from order_items oi
  join orders o on oi.order_id = o.order_id
  group by oi.product_id, month_start
),
ranked as (
  select 
    product_id,
    month_start,
    revenue,
    lag(revenue, 1) over (partition by product_id order by month_start) as prev1,
    lag(revenue, 2) over (partition by product_id order by month_start) as prev2
  from monthly_prod
)
select distinct r.product_id
from ranked r
where r.prev2 is not null
  and r.prev2 < r.prev1 and r.prev1 < r.revenue;

# Identify customers who only buy from one product category.
select 
  c.customer_id, 
  concat(c.first_name, ' ', c.last_name) as name,
  count(distinct p.category_id) as distinct_categories
from customers c
join orders o on o.customer_id = c.customer_id
join order_items oi on oi.order_id = o.order_id
join products p on p.product_id = oi.product_id
group by c.customer_id, name
having count(distinct p.category_id) = 1;

# Find the top 5% of customers contributing to total revenue
with cust_rev as (
  select 
    c.customer_id, 
    concat(c.first_name, ' ', c.last_name) as name,
    round(sum(oi.quantity * oi.list_price * (1 - coalesce(oi.discount, 0))),2) as revenue
  from customers c
  join orders o on o.customer_id = c.customer_id
  join order_items oi on oi.order_id = o.order_id
  group by c.customer_id, name
),
ranked as (
  select 
    customer_id,
    name,
    revenue,
    sum(revenue) over (order by revenue desc rows between unbounded preceding and current row) as cum_rev,
    sum(revenue) over () as total_rev,
    ntile(100) over (order by revenue desc) as percentile
  from cust_rev
)
select customer_id, name, revenue
from ranked
where percentile <= 5
order by revenue desc;