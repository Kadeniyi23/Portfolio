/*
To create a database named Sales_Data_Customer_Analysis
*/
CREATE DATABASE Customer_Analysis

use Customer_Analysis

/* After importing the excel file to examine the content of the customer analysis file, viewing the content of the data*/

Select *
from Customer_Analysis.dbo.Sales_data
/*In order to ensure data consistency and integrity, splitting the Data set into
three tables with Customer Data, Product info and Transaction Information.
*/
-- to create the Table with Transaction information--

use Customer_Analysis
Create Table dbo.Transaction_Info
(TransactionID varchar(10) primary key not null,
CustomerID char(4),
ProductID char(3),
Quantity int,
Price float,
Discount float,
TransactionDate datetime,
PaymentMethod varchar(50)
)



Insert into Customer_Analysis.dbo.Transaction_Info
select TransactionID, CustomerID, ProductID,Quantity,Price ,Discount,TransactionDate,PaymentMethod 
from Customer_Analysis.dbo.Sales_data

select *
from Customer_Analysis.dbo.Transaction_Info

-- to create the table with Customer Information; The data is very messy and does not contain consistent data, so efforts are made to ensure conformed data
Create Table Customer_Analysis.dbo.Customer_Info
(CustomerID char(4) primary key,
Location varchar(250),
Age int,
Gender varchar(10),
IncomeGroup varchar(10),
LoyaltyScore float
)

Create Table Customer_Information
(CustomerID char(4),
Location varchar(250),
Age int,
Gender varchar(10),
IncomeGroup varchar(10),
LoyaltyScore float
)

insert into Customer_Information
select CustomerID, CustomerLocation,CustomerAge,CustomerGender,CustomerIncomeGroup,CustomerLoyaltyScore
from Customer_Analysis.dbo.Sales_data

insert into Customer_Info
SELECT distinct ci.CustomerID, 
       first_data.Real_Location,
       first_data.Real_Age, 
       first_data.Real_Gender, 
       first_data.Real_Income_Group, 
       first_data.Real_Loyalty_Score
FROM Customer_Information ci
JOIN (
    SELECT CustomerID, 
           Age AS Real_Age, 
           Location AS Real_Location, 
           Gender AS Real_Gender, 
           IncomeGroup AS Real_Income_Group, 
           LoyaltyScore AS Real_Loyalty_Score,
           ROW_NUMBER() OVER (PARTITION BY CustomerID order by CustomerID) AS rn
    FROM Customer_Information
) first_data ON ci.CustomerID = first_data.CustomerID AND first_data.rn = 1;


Select *
from Customer_Info

--Similarly creating a table for products
Create Table Product_Information
(ProductID char(3),
Category varchar(20)
)
insert into Product_Information
select ProductID, ProductCategory
from Customer_Analysis.dbo.Sales_data

Create Table  Customer_Analysis.dbo.Product_Info
(ProductID char(3) primary key,
Category varchar(20)
)

insert into Customer_Analysis.dbo.Product_Info
SELECT distinct pi.ProductID, 
       first_data.Category
FROM Product_Information pi
JOIN (
    SELECT ProductID, 
           Category,
           ROW_NUMBER() OVER (PARTITION BY ProductID order by ProductID) AS rn
    FROM Product_Information
) first_data ON pi.ProductID = first_data.ProductID AND first_data.rn = 1;

select *
from Customer_Analysis.dbo.Product_Info

-- to view the content of the joined tables
Select ti.*
from Customer_Analysis.dbo.Transaction_Info as ti
join Customer_Info ci on ci.CustomerID=ti.CustomerID
join Customer_Analysis.dbo.Product_Info pi on pi.ProductID=ti.ProductID

/*Exploratory Analysis*/

--- to view how many transaction happened per day,month and year

--seperate the date month and year of the transaction date
alter table Transaction_Info
add Day Int

alter table Transaction_Info
add Month varchar(15)

alter table Transaction_Info
add Year int

alter table Transaction_Info
add DayofWeek varchar(15)

Update Transaction_Info
Set Day= datepart(day,TransactionDate)

Update Transaction_Info
Set Month= datename(month,TransactionDate)

Update Transaction_Info
Set Year= datepart(Year,TransactionDate)

UPDATE Transaction_Info
SET DayofWeek = DATENAME(weekday, TransactionDate);

Select *
from Transaction_Info

--- to view the number of transaction and total amount realized by month and year 
Select Month,Year,count(*) No_of_Transaction, round(sum(Price),2) Total_amount
from Transaction_Info
group by Month, Year
Order by Year,Month

--which days sold the most

Select DayofWeek,count(*) No_of_Transaction, round(sum(Price),2) Total_amount
from Transaction_Info
group by DayofWeek
Order by DayofWeek
--- reviewing customer information, to view how Each age group, Gender and Income Group purchased and which product sold the most
--creating 

-- categorize age groups 

alter table Customer_Info
add Age_group varchar(15)


UPDATE Customer_Info
SET Age_group= CASE
        WHEN Age BETWEEN 18 AND 29 THEN '18-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN Age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60-69'
		END;

WITH Total_Spent AS (
    SELECT 
        ci.Age_group,
        ci.Gender,
        ci.IncomeGroup,
        ti.ProductID,
        SUM(ti.Price) AS Total_Spent
    FROM 
        Customer_Analysis.dbo.Transaction_Info AS ti
    JOIN 
        Customer_Info ci ON ci.CustomerID = ti.CustomerID
    GROUP BY 
        ci.Age_group, 
        ci.Gender, 
        ci.IncomeGroup,
        ti.ProductID
),
Ranked_Products AS (
    SELECT 
        Age_group,
        Gender,
        IncomeGroup,
        ProductID,
        Total_Spent,
        ROW_NUMBER() OVER (PARTITION BY Age_group, Gender, IncomeGroup ORDER BY Total_Spent DESC) AS Product_Rank
    FROM 
        Total_Spent
)

SELECT 
    Age_group,
    Gender,
    IncomeGroup,
    Total_Spent,
    ProductID AS Most_Purchased_ProductID
FROM 
    Ranked_Products
WHERE 
    Product_Rank = 1
ORDER BY Total_Spent; -- Only select the most purchased product per group


--- which locations spent the most
Select ci.Location, Sum(ti.Price) as Total_spent_by_Location,
RANK() over(order by Sum(ti.Price) desc) as Rank
from Customer_Analysis.dbo.Transaction_Info as ti
join Customer_Info ci on ci.CustomerID=ti.CustomerID
group by ci.Location
order by Total_spent_by_Location desc

-- which category of items are purchased the most
Select Category,Sum(Quantity) Total_Quantity,round(Sum(Price),2) Total_Amount
from Transaction_Info ti
join Product_Info pi
on ti.ProductID=pi.ProductID
Group by Category
Order by Sum(Price)

--what is the average Loyalty Score accross each age group
select Age_group,Gender,AVG(LoyaltyScore) Average_Loyalty_Score
from Customer_Info
group by Age_group,Gender
order by Age_group,Gender

--Does Loyalty score correlate with Discount given
SELECT 
    (SUM((ti.Discount - avg_discount) * (ci.LoyaltyScore - avg_loyalty_score)) / 
     (SQRT(SUM(POWER(ti.Discount - avg_discount, 2)) * SUM(POWER(ci.LoyaltyScore - avg_loyalty_score, 2))))) AS Discount_Loyalty_Correlation
FROM 
    Transaction_Info ti
JOIN 
    Customer_Info ci 
ON 
    ti.CustomerID = ci.CustomerID
CROSS JOIN
    (SELECT 
        AVG(Discount) AS avg_discount, 
        AVG(LoyaltyScore) AS avg_loyalty_score 
     FROM 
        Transaction_Info ti
     JOIN 
        Customer_Info ci 
     ON 
        ti.CustomerID = ci.CustomerID) AS averages;

WITH Cohort AS (
    SELECT 
        CustomerID,
        MIN(TransactionDate) AS FirstPurchaseDate
    FROM 
        Transaction_Info
    GROUP BY 
        CustomerID
)
SELECT 
    YEAR(FirstPurchaseDate) AS CohortYear,
    COUNT(DISTINCT ci.CustomerID) AS CustomersInCohort,
    SUM(ti.Price) AS TotalRevenue
FROM 
    Transaction_Info ti
JOIN 
    Customer_Info ci ON ti.CustomerID = ci.CustomerID
JOIN 
    Cohort co ON ci.CustomerID = co.CustomerID
GROUP BY 
    YEAR(FirstPurchaseDate);
