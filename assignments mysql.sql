 -- 1)
SELECT employeeNumber, firstName , lastName 
FROM employees
WHERE jobTitle = 'Sales Rep' 
AND reportsTo = 1102;

-- 2)
select distinct productLine
from products
where productLine like '%cars';

-- 3) 
select customerNumber,customerName,
case
    when country in ('USA','Canada') then 'North America' 
    when country in ('UK','France','Germany') then 'Europe' 
    else 'Other'
   end as CustomerSegment
   from Customers;
   
  -- 4) 
SELECT productCode,SUM(quantityOrdered) AS totalQuantity
FROM OrderDetails
GROUP BY productCode
ORDER BY SUM(quantityOrdered) DESC
LIMIT 10;

  
  -- 5) 
  select monthName(paymentDate) as payment_month, count(*) as num_payments 
  from payments
  group by month(paymentDate)
  having num_payments > 20
  order by month(paymentDate);
  
  
  
  -- a) 
  -- Create the customers_Orders database
  create database if not exists Customers_Orders;
  
  -- Switch to the Customers_Orders database
  use Customers_Orders;
  
  -- Create the Customers table
  create table if not exists customers(
	  customer_id int auto_increment primary key,
      first_name varchar(50) not null,
      last_name varchar(50) not null,
      email varchar(255) unique,
      phone_number varchar(20) 
);
describe customers;
  
-- b) 
create table Orders (
     order_id int auto_increment primary key,
     customer_id int,
     order_date date,
     total_amount decimal(10,2),
     constraint fk_customer
          foreign key (customer_id)
          references customers(customer_id),
     constraint check_total_amount 
          check(total_amount > 0)
);
    describe Orders; 
    
    -- joins
   --  1) 
select country,count(customers.customerNumber) as order_count
from customers 
inner join orders on customers.customerNumber=orders.customerNumber
group by country 
order by order_count desc
limit 5;

  -- self joins
   -- Create the project table
CREATE TABLE project (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    Gender ENUM('Male', 'Female') NOT NULL,
    ManagerID INT
);

-- Insert data into the project table
INSERT INTO project (FullName, Gender, ManagerID) VALUES
('Pranaya', 'Male', 3),
('Priyanka', 'Female', 1),
('Preety', 'FeMale', NULL),
('Anurag', 'male', 1),
('Sambit', 'Male', 1),
('Rajesh', 'male', 3),
('Hina', 'Female', 3);

select m.FullName as ManagerName, e.FullName as EmpName 
from project e inner join project m on e.ManagerID = m.employeeID
where m.FullName in ('Pranaya','Preety')
order by m.FullName, e.FullName;

-- DDL Commands
create table facility (
    Facility_ID int,
    Name varchar(100),
    State varchar(100),
    Country varchar(100)
);

-- Alter the table to add primary key and auto increment
alter table facility
modify column Facility_ID int auto_increment,
add primary key (Facility_ID);

-- Add a new column 'City' after 'Name'
alter table facility
add column City varchar(100) not NULL after Name;

describe facility;

-- Views 

create view product_category_sales as 
select ProductLines.productLine,sum(Orderdetails.quantityOrdered * orderdetails.priceEach) as total_sales,
count(distinct orders.orderNumber) as number_of_orders
from productLines 
join products on productLines.productLines = products.productLines 
join orderdetails on products.productcode = orderdetails.productcode
join orders on orderdetails.orderNumber = orders.orderNumber
group by productLines.productLines;

SELECT * FROM product_category_sales;


-- Stored Procedure 
delimiter //
create procedure Get_country_payments(In input_year int, IN input_country varchar(255))
begin 
    select year(paymentDate) as year, country,concat(format(sum(amount) /1000,0), 'K') as TotalAmount 
	from payments 
    join Customers using (customerNumber)
    where year(paymentDate) = input_year and country = input_country 
    group by year,country ;
    
end //
delimiter ;
 
 call Get_country_payments(2003, 'France') ;

-- window functions 
-- a) 
select customers.customerName, 
count(orders.orderNumber) as Order_count,
dense_rank() over (order by count(orders.orderNumber) desc) as order_frequency_rnk
from customers
left join orders on customers.customerNumber = orders.customerNumber 
group by customers.customerName 
order by order_frequency_rnk;

-- b) 
with X as (
select
     YEAR(ORDERDATE) as Year ,
     monthname(orderdate) as month,
     count(orderdate) as total_orders 
     from orders 
     Group by year , month
)
select 
     year ,
     month,
     total_orders as 'Total Orders' ,
     concat(
       Round(
          100* (
          ( total_orders - LAG(total_orders) OVER (ORDER BY year)) / LAG(total_orders) OVER (ORDER BY year)
          ),0 ), "%" ) as " % YoY Changes"
from X ;


-- Subqueries and their applications 
select productLine ,count(*) as Total
from products
where MSRP > (select avg(MSRP) from products)
group by productLine
order by Total desc;

-- ERROR HANDLING in SQL
create table emp_eh(
EmpID int primary key ,
EmpName varchar(100),
EmailAddress varchar(100)
);

-- Create the Stored Procedure
delimiter //
create procedure Emp_EH (
	 In p_EmpID INT,
     In p_EmpName varchar(100),
     In p_EmailAddress varchar(100)
)

begin
    DECLARE exit handler FOR SQLEXCEPTION
    begin 
        select 'Error occurred' AS ErrorMessage;
    end; 
    Insert Into Emp_EH (EmpID,EmpName,EmailAddress)
    values (p_EmpID, p_EmpName, p_EmailAddress);
end //
delimiter ;

-- call the Stored Procedure
call Emp_EH(1, 'John Doe', 'john.doe@example.com'); 


-- TRIGGERS 

-- Create the table Emp_BIT
create table Emp_BIT (
	Name varchar(50),
    Occupation varchar(50),
    Working_date date,
    Working_hours int
);

-- Insert the data into Emp_BIT 
Insert into Emp_BIT values
('Robin', 'Scientist', '2020-10-04', 12),
('Warner', 'Engineer', '2020-10-04', 10),
('Peter', 'Actor', '2020-10-04', 13),
('Marco', 'Doctor', '2020-10-04', 14),
('Brayden', 'Teacher', '2020-10-04', 12),
('Antonio', 'Business', '2020-10-04', 11);

-- Create the before insert trigger 
delimiter //

create trigger before_insert_Working_hours
before insert on Emp_BIT
for each row
begin
    if  NEW.Working_hours < 0 then
        set NEW.Working_hours = abs(NEW.Working_hours);
	end if ;
end// 

delimiter ;

-- Test the trigger by inserting a row with negative Working_hours
insert into Emp_BIT values ('John', 'Artist', '2020-10-04', -8);

-- Check the table to see the inserted data
Select * from Emp_BIT;








 
