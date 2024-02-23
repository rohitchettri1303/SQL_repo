use gdb0041;
show tables;

-- #1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct(market) from dim_customer
where customer like '%Atliq Exclusive%' and region like '%APAC%';

-- #2 What is the percentage of unique product increase in 2021 vs. 2020?

select * from fact_sales_monthly;
with up1 as (
select count(distinct(product_code)) UniqueProducts_2020,fiscal_year from fact_sales_monthly
where fiscal_year = '2020'),
up2 as(  
select count(distinct(product_code)) UniqueProducts_2021,fiscal_year from fact_sales_monthly
where fiscal_year = '2021')
select up1.UniqueProducts_2020,up2.UniqueProducts_2021,round(((up2.UniqueProducts_2021 - up1.UniqueProducts_2020)/(up1.UniqueProducts_2020))*100,2) as Pct_change
from up1 cross join up2; 

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
 select * from dim_product;
 select segment,count(distinct(product_code)) UniqueProd_count from dim_product 
 group by 1
 order by 2 desc;
 
 -- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
 with up1 as (
  select p.segment ,  s.fiscal_year ,count(distinct(s.product_code)) UniqueProduct_cout2020 
  from fact_sales_monthly s 
  join dim_product p using(product_code)
  group by 1,2
  having s.fiscal_year = 2020
  order by 3 desc),
  up2 as (
  select p.segment ,  s.fiscal_year ,count(distinct(s.product_code)) UniqueProduct_cout2021 
  from fact_sales_monthly s 
  join dim_product p using(product_code)
  group by 1,2
  having s.fiscal_year = 2021
  order by 3 desc)
  select up2.segment as Segment,up1.UniqueProduct_cout2020 ,up2.UniqueProduct_cout2021,
  (up2.UniqueProduct_cout2021 - up1.UniqueProduct_cout2020) as difference
  from up2 
  join up1 on up1.segment = up2.segment
  order by difference desc;


-- Get the products that have the highest and lowest manufacturing costs
(select p.product_code,p.product,m.manufacturing_cost  from dim_product p
join fact_manufacturing_cost m using(product_code)
order by 3 desc limit 1)
union
(select p.product_code,p.product,m.manufacturing_cost  from dim_product p
join fact_manufacturing_cost m using(product_code)
order by 3  limit 1);
-- alternate method
select p.product_code,p.product,m.manufacturing_cost  from dim_product p
join fact_manufacturing_cost m using(product_code)
where m.manufacturing_cost in (select max(manufacturing_cost) from fact_manufacturing_cost
union select min(manufacturing_cost) from fact_manufacturing_cost);

-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select c.customer_code,c.customer,avg(p.pre_invoice_discount_pct) as Avg_pre_invoice_deduction from dim_customer c 
join fact_pre_invoice_deductions p using(customer_code) 
where p.fiscal_year = '2021' and c.market like '%India%'
group by 1,2
having Avg_pre_invoice_deduction > (select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions) 
order by 3 desc
limit 5;

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This
-- analysis helps to get an idea of low and high-performing
-- months and take strategic decisions.

select * from fact_sales_monthly;
select * from fact_gross_price;

select year(s.`date`) fiscal_year,monthname(s.`date`) Month_,round(sum(s.sold_quantity*g.gross_price),2) Gross_sales_Amount
 from fact_sales_monthly s
join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year 
join dim_customer c on c.customer_code = s.customer_code
where c.customer like '%Atliq Exclusive%'
group by 1,2
order by month(Month_);


-- In which quarter of 2020, got the maximum total_sold_quantity?

select concat('Q',quarter(`date`)) as Quarter_,sum(sold_quantity) as Total_Sold_quantity from fact_sales_monthly
where fiscal_year = '2020'
group by 1
order by 2 desc;

-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

select c.channel,
round(sum(s.sold_quantity*g.gross_price),2) Gross_sales_Amount,
(round(sum(s.sold_quantity*g.gross_price),2) / (select round(sum(s.sold_quantity*g.gross_price),2) Gross_sales_Amount
 from fact_sales_monthly s
join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year 
join dim_customer c on c.customer_code = s.customer_code
where s.fiscal_year = 2021))*100 as Perc_change
from fact_sales_monthly s
join dim_customer c on c.customer_code = s.customer_code
join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year 
where s.fiscal_year = 2021
group by 1
order by 3 desc;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
with t1 as (
select p.division,
p.product_code,p.product,sum(s.sold_quantity) Total_sold_quantity,
dense_rank() over(partition by division order by sum(s.sold_quantity) desc) Rank_
from fact_sales_monthly s
join  dim_product p on p.product_code = s.product_code
where s.fiscal_year = '2021'
group by 1,2,3)
select * from t1 where Rank_ <=3 ;
