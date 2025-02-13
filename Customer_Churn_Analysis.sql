--- to view the content of the table in Consumer Data
Use Customer_Churn_Analysis

select *
from Consumer_Data

---to view reasons for Churn
Select distinct Churn_category, Churn_reason
from Consumer_Data

--adding constraints for Binary columns,primary keys and not null
Alter table Consumer_Data
add constraint unique_Customer_ID unique(Customer_ID) 

Alter table Consumer_Data
add constraint primary_key_constraint primary key(Customer_ID)

Alter table Consumer_Data
add constraint Yes_no_constraint check (Churn_Label IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint1 check (Under_30 IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint2 check (Senior IN ('Yes', 'No'))


Alter table Consumer_Data
add constraint Yes_no_constraint3 check (Intl_Mins IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint4 check (Intl_Active IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint5 check (Intl_Plan IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint6 check (Unlimited_Data_Plan IN ('Yes', 'No'))

Alter table Consumer_Data
add constraint Yes_no_constraint7 check (Device_Protection_Online_Backup IN ('Yes', 'No'))

/*Exploratory Analysis*/

-- What is the churn rate
SELECT 
    (CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Consumer_Data)) * 100 AS Churn_Rate
FROM 
    Consumer_Data
WHERE 
    Churn_Label = 'Yes';

--Analysing which reason and categories for churn was most popular

Select Churn_category, Churn_reason, count(*) as No_of_times
from Consumer_Data
where Churn_Category is not null
group by Churn_Category, Churn_Reason
order by count(*) desc

-- what is the churn rate per gender 
Select Gender,Count(*) as Churned
from Consumer_Data
where Churn_Label='Yes'
group by Gender

/* The same number of men and women churned*/

--Churn Rate by state
SELECT 
    State,
    COUNT(Customer_ID) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY State
ORDER BY Churn_Rate DESC;

---Churn Analysis by Payment and Contract type
SELECT 
    Payment_Method,
    Contract_Type,
    COUNT(Customer_ID) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY Payment_Method, Contract_Type
ORDER BY Churn_Rate DESC;


---To understand Churn Rate against Age group and Contract Type
SELECT 
    CASE 
        WHEN Age < 30 THEN 'Under_30'
        WHEN Age BETWEEN 30 AND 60 THEN '30-60'
        ELSE 'Senior'
    END AS Age_Group,
    Contract_Type,
    COUNT(Customer_ID) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY 
    ROLLUP(CASE 
            WHEN Age < 30 THEN 'Under_30'
            WHEN Age BETWEEN 30 AND 60 THEN '30-60'
            ELSE 'Senior'
           END, Contract_Type);

--- International plans;Does it affect Churn Rate
SELECT 
    Intl_Plan,
    AVG(Extra_International_Charges) AS Avg_Extra_Intl_Charges,
    COUNT(Customer_ID) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY Intl_Plan
ORDER BY Churn_Rate DESC;

--Payment type vs Churn Rate
SELECT 
    Payment_Method,
    COUNT(Customer_ID) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY 
    Payment_Method
ORDER BY 
    Churn_Rate DESC;

--Do customer with extra charges churn more?
SELECT 
    Unlimited_Data_Plan,
    AVG(Extra_Data_Charges) AS Avg_Extra_Data_Charges,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_ID), 2) AS Churn_Rate
FROM 
    Consumer_Data
GROUP BY 
    Unlimited_Data_Plan;


--
SELECT 
    Contract_Type,
    Churn_Label,
    Avg_Monthly_Charge,
    Avg_Total_Charges
FROM (
    SELECT 
        Contract_Type,
        Churn_Label,
        AVG(Monthly_Charge) AS Avg_Monthly_Charge,
        AVG(Total_Charges) AS Avg_Total_Charges
    FROM Consumer_Data
    GROUP BY Contract_Type, Churn_Label
) AS Charges_Subquery
ORDER BY Avg_Monthly_Charge DESC;




