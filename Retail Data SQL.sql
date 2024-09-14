-- Use DataBase
USE [Case Study- Retail Data Analysis];

/* As you would have noticed, the dates provided across the datasets are not in a correct format. As first step is to convert the
date variable into a valid date formats before proceeding ahead.*/ 

--So for the above we are making another table with copy data from original. 


-- Copy Customer table data Into new table Customers 
SELECT * INTO Customers
FROM Customer;

-- Copy Transactions table data Into new table Transaction
SELECT * INTO [Transaction]
FROM Transactions;

--Alter The both new table column of DOB and Tran_Id as Data Type only Date

ALTER TABLE Customers
ALTER COLUMN DOB DATE;

ALTER TABLE [Transaction]
ALTER COLUMN Tran_Date DATE;


 ---------------------------------------------Data Prepration & Understanding----------------------------------------------------

-- 1- What is the total number of rows in each of the 3 tables in the database?

SELECT COUNT(*) AS No_of_Rows FROM Customer;
SELECT COUNT(*) AS No_of_Rows FROM Transactions;
SELECT COUNT(*) AS No_of_Rows FROM Prod_cat_info;

--2- What is the total no of transactions that have a return?
SELECT COUNT(Total_Amt) AS No_of_Transactions
FROM Transactions
WHERE total_amt <= 0;

/* 3- As you would have noticed, the dates provided across the datasets are not in a correct format. As first step is to convert the
date variable into a valid date formats before proceeding ahead.*/ 

SELECT CONVERT(DATE, DOB, 105) as Date_of_Birth FROM Customer; -- For customet table

SELECT CONVERT(DATE, Tran_Date, 105) AS Tran_Date FROM Transactions; -- For Transactions Table

/* 4- What is the time range of the transactions of data available for analysis? Show the output in number of days, month
and years simultaneously in different columns.
*/
SELECT MIN(CONVERT(DATE, Tran_Date, 105)) AS Start_Date,
MAX(CONVERT(DATE, Tran_Date, 105)) AS Last_Date,
DATEDIFF(DAY, MIN(Tran_Date), MAX(Tran_Date)) AS Total_Days,
DATEDIFF(MONTH, MIN(Tran_Date), MAX(Tran_Date)) AS Total_Months,
DATEDIFF(YEAR, MIN(Tran_Date), MAX(Tran_Date)) AS Total_Years
FROM Transactions;

-- 5- Which Product Category does the sub-Category "DIY" belong to?

SELECT prod_cat
FROM Prod_cat_info
WHERE prod_subcat = 'DIY';


----------------------------------------------------Data Analysis----------------------------------------------------------------
SELECT * FROM Customer;
SELECT * FROM Transactions;
SELECT * FROM Prod_cat_info;

-- 1- Which Channel is Most frequent used for the transactions?
SELECT TOP 1 Store_Type, COUNT(Store_Type) AS Most_Frequent_Channel
FROM Transactions
GROUP BY Store_type
ORDER BY Most_Frequent_Channel DESC;

-- 2- What is the count of male and female customers in the database?
SELECT 'Male' as GENDER, COUNT(Gender) AS Total_Male
FROM Customer
WHERE Gender = 'M'

UNION ALL

SELECT 'Female' AS Gender, COUNT(Gender) AS Total_Female
FROM Customer
WHERE Gender = 'F';

-- 3- FROM Which city do we have the maximum number of customers and how many?
--Method-1
SELECT TOP 1 C.City_Code, COUNT(T.Cust_Id) AS TOTAL
FROM Customer AS C
INNER JOIN Transactions AS T
ON C.customer_Id = T.cust_id
GROUP BY city_code
ORDER BY TOTAL DESC;

--Method-2
SELECT TOP 1 City_Code, COUNT(customer_Id) AS Maximum_Customer
FROM Customer
GROUP BY city_code
ORDER BY Maximum_Customer DESC;

-- 4- How many sub_category are there under the Books Category
SELECT Prod_Cat, COUNT(Prod_Subcat) AS Total_Sub_Category 
FROM Prod_cat_info
WHERE prod_cat = 'Books'
GROUP BY prod_cat;

--5- What is maximum quantity of products ever ordered?
SELECT TOP 1 Products.Prod_cat, COUNT(CAST(Trans.Qty AS FLOAT)) AS Quantity
FROM Transactions AS Trans
INNER JOIN Prod_cat_info AS Products
ON Trans.prod_cat_code = Products.prod_cat_code
AND Products.prod_sub_cat_code = Trans.prod_subcat_code
GROUP BY Products.prod_cat
ORDER BY Quantity DESC;

-- 6- What is the net total revenue generated in categories Electronics and Books?

--Method-1
SELECT Products.Prod_Cat, SUM(CAST(Trans.Total_amt AS FLOAT)) AS Revenue
FROM Transactions AS Trans
INNER JOIN Prod_cat_info AS Products
ON Trans.prod_cat_code = Products.prod_cat_code
WHERE Products.prod_cat IN ('Electronics', 'Books')
GROUP BY Products.prod_cat;

--Method-2
SELECT Products.Prod_Cat, SUM(CAST(Trans.Total_amt AS DECIMAL(18,2))) AS Revenue
FROM Transactions AS Trans
INNER JOIN Prod_cat_info AS Products
ON Trans.prod_cat_code = Products.prod_cat_code
AND Trans.prod_subcat_code = Products.prod_sub_cat_code
WHERE Products.prod_cat IN ('Electronics', 'Books')
GROUP BY Products.prod_cat;

-- 7- How many customer have>10 transactions with us, excluding return?
SELECT COUNT(Cust_Id) AS Total_Customer 
FROM (
SELECT Cust_id, COUNT(Transaction_id) AS Total_Trans
FROM Transactions
WHERE total_amt >0
GROUP BY Cust_id
HAVING COUNT(Transaction_id) > 10
) AS Subquery

-- 8- What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?
SELECT Products.Prod_Cat, SUM(CAST(Trans.Total_Amt AS DECIMAL(18,2))) AS Revenue
FROM Transactions AS Trans
LEFT JOIN Prod_cat_info AS Products
ON Trans.prod_cat_code = Products.prod_cat_code
AND Trans.prod_subcat_code = Products.prod_sub_cat_code
WHERE Products.prod_cat IN ('Electronics', 'Clothing')
AND Trans.Store_type = 'Flagship store'
GROUP BY Products.prod_cat

UNION ALL

SELECT 'Grand Total' AS Combined_Revenue, SUM(CAST(Trans.Total_Amt AS DECIMAL(18,2))) AS Revenue
FROM Transactions AS Trans
LEFT JOIN Prod_cat_info AS Products
ON Trans.prod_cat_code = Products.prod_cat_code
AND Trans.prod_subcat_code = Products.prod_sub_cat_code
WHERE Products.prod_cat IN ('Electronics', 'Clothing')
AND Trans.Store_type = 'Flagship store';


/* 9-What is the total revenue generated from "Male" customers in  "Electronics" category? Output Should display total revenue by
prod sub_cat. */

SELECT 'Male' AS Gender, Prod_Info.Prod_cat, Prod_info.Prod_subcat,
SUM(Trans.Total_amt) AS Revenue
FROM Customer AS Cust
INNER JOIN Transactions AS Trans
ON Cust.customer_Id = Trans.cust_id
INNER JOIN Prod_cat_info AS Prod_Info
ON Trans.prod_cat_code = Prod_Info.prod_cat_code
AND Trans.prod_subcat_code = Prod_Info.prod_sub_cat_code
WHERE Cust.Gender = 'M' AND Prod_Info.prod_cat = 'Electronics'
GROUP BY Cust.Gender, Prod_Info.Prod_cat, Prod_info.Prod_subcat;

-- 10- What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

--Step-1- Calculate Total Sales and Total Return per Product Subcategory
WITH SubCategorySales AS (
                        SELECT Prod_Info.Prod_Subcat,
						       Prod_info.Prod_cat,
							   SUM(CASE 
							           WHEN Trans.total_amt > 0 THEN CAST(Trans.Total_amt AS FLOAT) 
							           ELSE 0
									   END) AS Total_Sales,
							   SUM(CASE
							            WHEN Trans.total_amt < 0 THEN ABS(CAST(Trans.Total_amt AS FLOAT))
										ELSE 0
										END) AS Total_Return
						 FROM Transactions AS Trans
						 LEFT JOIN Prod_cat_info AS Prod_Info
						      ON Trans.prod_cat_code = Prod_Info.prod_cat_code
						      AND Trans.prod_subcat_code = Prod_info.prod_sub_cat_code
						 GROUP BY Prod_Info.prod_subcat, Prod_Info.prod_cat),

--Step-2- Top 5 Subcategory by TotalSales
Top5Subcategories AS (
                       SELECT TOP 5 Prod_Subcat, Prod_cat, Total_Sales, Total_Return
					   FROM SubCategorySales
					   ORDER BY Total_Sales DESC)

--Step-3- Calculate percentage of sales and return for each subcategory
SELECT Prod_Subcat, Prod_cat, Total_Sales, Total_Return,
(Total_Sales / (Total_Sales + Total_Return)) * 100 AS PercentageSales,
(Total_Return / (Total_Sales + Total_Return)) * 100 AS PercentageReturn
							    FROM Top5Subcategories;  

/* 11- For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers by these 
consumers in last 30 days of transactions from max transaction date available in the data? */

--Method-1
SELECT Cust.customer_Id, Cust.DOB, DATEDIFF(YEAR, CONVERT(DATE, DOB, 105), GETDATE()) AS Age,
SUM(Trans.total_amt) AS Total_Revenue
FROM  Customer AS Cust
INNER JOIN Transactions AS Trans
ON Cust.customer_Id = Trans.cust_id
WHERE DATEDIFF(YEAR, CONVERT(DATE, DOB, 105), GETDATE()) BETWEEN 25 AND 35
AND Trans.tran_date BETWEEN DATEADD(DAY, -30, (SELECT MAX(Tran_Date) FROM Transactions))
AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY Cust.customer_Id, Cust.DOB;


--Method-2
WITH MaxTransDate AS (
    SELECT MAX(Trans.tran_date) AS Max_Date
    FROM Transactions AS Trans
),
RecentTransactions AS (
    SELECT Trans.cust_id, Trans.total_amt
    FROM Transactions AS Trans
    INNER JOIN MaxTransDate AS MTD
    ON Trans.tran_date BETWEEN DATEADD(DAY, -30, MTD.Max_Date) AND MTD.Max_Date
)
SELECT 
    Cust.customer_Id, 
    Cust.DOB, 
    DATEDIFF(YEAR, CONVERT(DATE, Cust.DOB, 105), GETDATE()) AS Age,
    SUM(RecentTrans.total_amt) AS Net_Total_Revenue
FROM  
    Customer AS Cust
INNER JOIN 
    RecentTransactions AS RecentTrans
ON 
    Cust.customer_Id = RecentTrans.cust_id
WHERE 
    DATEDIFF(YEAR, CONVERT(DATE, Cust.DOB, 105), GETDATE()) BETWEEN 25 AND 35
GROUP BY 
    Cust.customer_Id, Cust.DOB;


-- 12- Which product category has been the max value of returns in the last 3 months of transactions?

   -- Step 1: Define CTE to calculate total returns for the last 3 months
WITH Recent_Returns AS (
    SELECT 
        Prod.Prod_cat, 
        SUM(CASE 
            WHEN Trans.total_amt < 0 THEN CAST(Trans.total_amt AS FLOAT)
            ELSE 0 
        END) AS Total_Return
    FROM 
        Transactions AS Trans
    INNER JOIN 
        Prod_cat_info AS Prod
    ON 
        Trans.prod_cat_code = Prod.prod_cat_code
        AND Trans.prod_subcat_code = Prod.prod_sub_cat_code
    WHERE 
        Trans.tran_date BETWEEN DATEADD(MONTH, -3, (SELECT MAX(CONVERT(DATE, Tran_Date, 105)) FROM Transactions))
        AND (SELECT MAX(CONVERT(DATE, Tran_Date, 105)) FROM Transactions)
    GROUP BY 
        Prod.Prod_cat
)

-- Step 2: Query the CTE to find the product category with the maximum total return
SELECT TOP 1
    Prod_cat,
    Total_Return
FROM 
    Recent_Returns
ORDER BY 
    Total_Return DESC;

-- 13- Which store-type sells the maximum products; by value of sales amount and by quantity sold?

--Method-1

WITH StoreSums AS (
    SELECT STORE_TYPE, SUM(CAST(TOTAL_AMT AS FLOAT)) AS TOT_SALES, SUM(CAST(QTY AS FLOAT)) AS TOT_QUAN
    FROM Transactions
    GROUP BY STORE_TYPE
)
SELECT STORE_TYPE, TOT_SALES, TOT_QUAN
FROM StoreSums
WHERE TOT_SALES = (SELECT MAX(TOT_SALES) FROM StoreSums)
AND TOT_QUAN = (SELECT MAX(TOT_QUAN) FROM StoreSums);

--Method-2

SELECT TOP 1 Trans.Store_type, SUM(CAST(total_amt AS FLOAT)) AS Total_Sales_Amount,
SUM(CAST(Qty AS FLOAT)) AS Quantity_of_Sales
FROM
Transactions AS Trans
INNER JOIN prod_cat_info AS Prod_Info
ON Trans.prod_cat_code=Prod_Info.prod_cat_code AND Trans.prod_subcat_code=Prod_Info.prod_sub_cat_code
GROUP BY Store_type
ORDER BY Total_Sales_Amount DESC, Quantity_of_Sales DESC;

-- 14- What are the category for which average revenue is above the overall average?

SELECT Prod_Info.Prod_cat, AVG(Trans.total_amt) AS Average
FROM Transactions AS Trans
INNER JOIN Prod_cat_info AS Prod_Info
ON Trans.prod_cat_code = Prod_Info.prod_cat_code
AND Trans.prod_subcat_code = Prod_Info.prod_sub_cat_code
GROUP BY Prod_Info.prod_cat
HAVING AVG(Trans.total_amt) > (SELECT AVG(total_amt) FROM Transactions);

/* 15- Find the average and total revenue by each subcatrgory for the categories which are among top 5 category in terms of 
quantity sold? */

SELECT Prod_Info.Prod_Cat, Prod_Info.Prod_subcat, 
AVG(CAST(TRANS.total_amt AS FLOAT)) AS Average_Revenue,
SUM(CAST(TRANS.total_amt AS FLOAT)) AS Total_Revenue
FROM Transactions AS Trans
INNER JOIN Prod_cat_info AS Prod_Info
ON Trans.prod_cat_code = Prod_Info.prod_cat_code 
AND Trans.prod_subcat_code = Prod_Info.prod_sub_cat_code
WHERE Prod_Info.prod_cat IN 
                            ( SELECT TOP 5 prod_cat 
                              FROM Transactions AS Trans
							  INNER JOIN Prod_cat_info AS Prod_Info
							  ON Trans.prod_cat_code = Prod_Info.prod_cat_code
							  AND Trans.prod_subcat_code = Prod_Info.prod_sub_cat_code
							  GROUP BY Prod_Info.prod_cat
							  ORDER BY SUM(CAST(Trans.Qty AS FLOAT)) DESC)
GROUP BY Prod_Info.prod_cat, Prod_Info.prod_subcat;
 
