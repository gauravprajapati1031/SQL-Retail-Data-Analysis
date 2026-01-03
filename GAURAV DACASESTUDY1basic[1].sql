CREATE DATABASE GAURAV_CASESTUDY1


--DATA PREPARATION AND UNDERSTANDING
--1.	What is the total number of rows in each of the 3 tables in the database?
select*from(
select 'Customer' as TABLE_NAME,COUNT(*) as TOTAL_NO_OF_RECORDS from Customer union all
select 'prod_cat_info' as TABLE_NAME,COUNT(*) as TOTAL_NO_OF_RECORDS from prod_cat_info union all
select 'Transactions' as TABLE_NAME,COUNT(*) as TOTAL_NO_OF_RECORDS from Transactions 
) TBL


--2.	What is the total number of transactions that have a return?
select coalesce(store_type ,'TotalReturnsRecd') Store_type ,  COUNT( transaction_id) Return_Count from Transactions
where Qty<0
group by rollup (Store_type) 
order by COUNT(transaction_id) desc

/*3.	As you would have noticed, the dates provided across the datasets are not in a
correct format. As first steps, pls convert the date variables into valid date formats
before proceeding ahead.
*/

--date in customer table fixed in DOB_Fixed column
select *,convert(varchar(10),DATEFROMPARTS(DATEPART(year,DOB),DATEPART(MONTH,DOB),Datepart(DAY,DOB)),105) as DOB_Fixed from Customer


--date in transactions table fixed in tran_date_fixed
select *,convert(varchar(10),DATEFROMPARTS(DATEPART(year,tran_date),DATEPART(MONTH,tran_date),Datepart(DAY,tran_date)),105) as tran_date_fixed  from Transactions


/*4.	What is the time range of the transaction data available for analysis? Show the 
output in number of days, months and years simultaneously in different columns.
*/
 SELECT 
    MIN(tran_date) AS start_date,
    MAX(tran_date) AS end_date,
    DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) AS total_days,
    DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS total_months,
    DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS total_years
FROM transactions;

--5.	Which product category does the sub-category “DIY” belong to?
select prod_cat,prod_subcat from prod_cat_info
where prod_subcat='DIY'






--DATA ANALYSIS
--1.	Which channel is most frequently used for transactions?
select top 1 Store_type,COUNT(transaction_id) Usage from Transactions
group by Store_type
order by COUNT(transaction_id) desc
--2.	What is the count of Male and Female customers in the database?
select Gender,COUNT(customer_Id) Customer_Count from Customer
where Gender is not null
group by Gender
order by COUNT(customer_Id)
--3.	From which city do we have the maximum number of customers and how many?
select top 1 city_code,COUNT(customer_Id) customer_count from Customer
group by city_code
order by customer_count desc
--4.	How many sub-categories are there under the Books category?
select prod_cat,prod_cat_code,prod_subcat from prod_cat_info
where prod_cat='Books'
order by prod_cat_code
--5.	What is the maximum quantity of products ever ordered?
select top 1 cust_id,Qty,total_amt from Transactions
order by Qty desc

--6.	What is the net total revenue generated in categories Electronics and Books?
select coalesce(prod_cat,'total_revenue') prod_cat,sum(total_amt) Revenue from Transactions as a
left join prod_cat_info as b on a.prod_subcat_code=b.prod_sub_cat_code
group by  rollup (prod_cat)
order by sum(total_amt)
--7.	How many customers have >10 transactions with us, excluding returns?
select customer_Id,COUNT(transaction_id) transact_count from Customer as a
right join Transactions as b on b.cust_id=a.customer_Id
where  b.Qty>0
group by customer_Id
having COUNT(transaction_id)>10 
order by COUNT(transaction_id)

--8.	What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
-- combined revenue--rollup function
--category from prod_category_info
--revenue--total amount--transactions table
--join transactions table and prod_category_info (left)
--coalesce--total revnue title

select coalesce(prod_cat,'Combined_Revenue') prod_cat,SUM(total_amt) Revenue from Transactions as a
left join prod_cat_info as b on a.prod_cat_code=b.prod_cat_code
where prod_cat='Electronics' or prod_cat='Clothing'
group by rollup (prod_cat)
order by SUM(total_amt)
--9.	What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.
--total revenue--total amount sum--transactions
--where customers are 'MALE'--customer table
--category is electronics--prod_cat_info
--joins-- left join transactions table to customer table, 
--right join prod_cat_info to transactions
--rollup on sum total amount by prod_sub_cat
--coalesce (prod_sub_cat,'Total Revenue')

select coalesce(c.prod_subcat,'Total Revnue') prod_subcat,SUM(a.total_amt) Revenue from  Transactions as a
left join Customer as b on a.cust_id=b.customer_Id
right join prod_cat_info as c on c.prod_cat_code=a.prod_cat_code
where b.Gender='M' and c.prod_cat='Electronics'
group by rollup(prod_subcat);
--10.	What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
----percentage of sales and returns -- total amount/sum(total amount)*100 group by subcategory
----select only top 5 categories in terms of sales-- sales= sum(total amount)--group by category


select x.* , y.[%change]   from(
	select prod_subcat ,
	SUM(total_amt) / (select SUM(total_amt) from Transactions where Qty > 0) *100 [%change]
	from Transactions as a
	join prod_cat_info as b
	on a.prod_cat_code = b.prod_cat_code and a.prod_subcat_code = b.prod_sub_cat_code
	where Qty > 0
	group by prod_subcat
) as x
join
(select prod_subcat ,
SUM(total_amt) / (select SUM(total_amt) from Transactions where Qty < 0) *100 [%change]
from Transactions as a
join prod_cat_info as b
on a.prod_cat_code = b.prod_cat_code and a.prod_subcat_code = b.prod_sub_cat_code
where Qty < 0
group by prod_subcat ) as y on x.prod_subcat = y.prod_subcat


--11.	For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?
select tran_date, DATEDIFF(YEAR,DOB,GETDATE()) AGE,SUM(total_amt) revenue   from Transactions as a
left join Customer as b on a.cust_id=b.customer_Id
where DATEDIFF(YEAR,DOB,GETDATE()) between 25 and 35  and 

DATEDIFF(DD,tran_date,(select top 1 tran_date from Transactions order by tran_date desc))<=30
group by tran_date,DOB
--problem of not getting total in this------------

--12.	Which product category has seen the max value of returns in the last 3 months of transactions?
--top 1 product category from prod_cat_info
--basis of max returns i.e. max negative total amt from transaction
--datediff  last 3 months of transactions

select top 1  c.prod_cat,SUM(total_amt) revenue from Transactions as a
left join Customer as b on a.cust_id=b.customer_Id
right join prod_cat_info as c on c.prod_cat_code=a.prod_cat_code
where a.Qty<0 and 
DATEDIFF(MONTH,tran_date,(select top 1 tran_date from Transactions order by tran_date desc))<=3
group by c.prod_cat
Order by revenue

--13.	Which store-type sells the maximum products; by value of sales amount and by quantity sold?
select top 1 Store_type,Qty,total_amt from Transactions
order by total_amt desc, Qty desc

--14.	What are the categories for which average revenue is above the overall average.
select prod_cat,AVG(total_amt) average_revenue from Transactions a
left join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
group by prod_cat
having AVG(total_amt)> (select AVG(total_amt) from Transactions)

--15.	Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
--average revenue and total revenue of each subcategory-- average(total_amt), sum(total_amt)
--categories in top 5 in terms of quantity sold-- top 5 function, sum(qty) group by category, order by sum(qty) desc
--subquery (average and total revenue grouping by subcategory)-- by joining prod_cat_info and transactions

select  b.prod_cat,COALESCE(b.prod_subcat,'TOTAL') pro_subcat,AVG(total_amt) average_revenue, SUM(total_amt) total_revenue
from Transactions a
left join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
where exists(
select* from (
select top 5 b.prod_cat,SUM(Qty) total_sold
from Transactions a
left join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
group by b.prod_cat
order by SUM(Qty) desc
) TBL  where b.prod_cat=TBL.prod_cat)
group by  cube( b.prod_subcat),b.prod_cat
