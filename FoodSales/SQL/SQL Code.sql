USE portfolio_project_food_sales;

-- Table structure for table 'salesperson'
DROP TABLE IF EXISTS salesperson;
CREATE TABLE salesperson (
  SalespersonKey INT UNSIGNED NOT NULL,
  FirstName TEXT,
  LastName TEXT,
  Gender TEXT,
  CONSTRAINT pk_salesperson_key PRIMARY KEY (SalespersonKey)
);

-- Table structure for table 'products'
DROP TABLE IF EXISTS products;
CREATE TABLE products (
  ProductKey INT UNSIGNED NOT NULL,
  ProductName TEXT,
  ProductGroup TEXT,
  ProductCategory TEXT,
  CONSTRAINT pk_product_key PRIMARY KEY (ProductKey)
);

-- Table structure for table 'orders'
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    OrderDate TEXT,
    OrderNumber INT UNSIGNED NOT NULL,
    SalespersonKey INT UNSIGNED NOT NULL,
    SupervisorKey INT UNSIGNED NOT NULL,
    ManagerKey INT UNSIGNED NOT NULL,
    SalesChannel TEXT,
    CONSTRAINT pk_order_number PRIMARY KEY (OrderNumber),
    CONSTRAINT fk_salesperson_key FOREIGN KEY (SalespersonKey)
        REFERENCES salesperson(SalespersonKey)
);

-- Table structure for table 'order_details'
DROP TABLE IF EXISTS order_details;
CREATE TABLE order_details (
    OrderNumber INT UNSIGNED NOT NULL,
    ProductKey INT UNSIGNED NOT NULL,
    Quantity SMALLINT UNSIGNED NOT NULL,
    UnitPrice FLOAT(5 , 2 ),
    CONSTRAINT pk_order_number_product_key PRIMARY KEY (OrderNumber, ProductKey),
    CONSTRAINT fk_order_number FOREIGN KEY (OrderNumber)
        REFERENCES orders(OrderNumber),
    CONSTRAINT fk_product_key FOREIGN KEY (ProductKey)
        REFERENCES products(ProductKey)
);



-- Filling table 'salesperson'
INSERT INTO salesperson VALUES (102,'Phil','Barth','M'),
(125,'John','Rinn','M'),
-- 9 RECORDS ELIMINATED (SPACE REDUCTION)
(669,'Shyla','Kumar','F');


-- Filling table 'products'
INSERT INTO products VALUES (108,'Product 108','Ground Coffee','Food'),
(111,'Product 111','Vegetable','Food'),
-- 795 RECORDS ELIMINATED (SPACE REDUCTION)
(2687,'Product 2687','Yeasts','Food');


-- Filling table 'orders'
INSERT INTO orders VALUES ('43477',1492762,265,186,149,'Distributor'),
('43478',1492719,265,186,149,'Distributor'),
-- 52557 RECORDS ELIMINATED (SPACE REDUCTION)
('44268',2172961,215,305,288,'Retail');


-- Filling table 'order_details'
INSERT INTO order_details VALUES (1492762,1420,6,4.44),
(1492762,1073,6,8.83),
-- 260093 RECORDS ELIMINATED (SPACE REDUCTION)
(2172961,257,6,4.42);




-- Data exploration queries

USE portfolio_project_food_sales;

-- Simple queries (using 1 table):

-- List all salesperson whose last name is Williams. Show both the first and last name on one column.

SELECT 
    SalespersonKey,
    CONCAT_WS(' ', FirstName, LastName) AS FullName
FROM
    salesperson
WHERE
    LastName = 'Williams';


-- How many products there are on each product group? Rank the answer by product group amount .

SELECT 
    ProductGroup, COUNT(ProductKey) AS ProdCount
FROM
    products
GROUP BY ProductGroup
ORDER BY ProdCount DESC, ProductGroup;


-- How many orders have been placed so far?

SELECT 
    COUNT(OrderNumber) AS OrdersCount
FROM
    orders;


-- How much is the total revenue so far? Round the answer, without decimal places.

SELECT 
    ROUND(SUM(Quantity * UnitPrice),0) AS TotalRevenue
FROM
    order_details;
    
    
-- Rank the 5 orders with the highest amount of items involved.

SELECT 
    OrderNumber,
    SUM(Quantity) AS ItemsCount
FROM
    order_details
GROUP BY OrderNumber
ORDER BY ItemsCount DESC
LIMIT 5;


-- Rank the 5 orders with the highest revenue.

SELECT 
    OrderNumber,
    SUM(Quantity * UnitPrice) AS OrderRevenue
FROM
    order_details
GROUP BY OrderNumber
ORDER BY OrderRevenue DESC
LIMIT 5;


-- Which is the order with the highest average item price?

SELECT 
    OrderNumber,
    ((SUM(Quantity * UnitPrice)) / (SUM(Quantity))) AS AvgItemPrice
FROM
    order_details
GROUP BY OrderNumber
ORDER BY AvgItemPrice DESC
LIMIT 1;



-- Complex queries (using 2 or more tables):

-- Which is the Revenue for the product group "Vegetable"?

SELECT 
    p.ProductGroup, SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM
    order_details od
        JOIN
    products p ON od.ProductKey = p.ProductKey
WHERE
    p.ProductGroup = 'Vegetable';


-- Which is the total revenue by Channel, considerating only the orders placed by female staff?

SELECT 
    o.SalesChannel, SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM
    orders o
        JOIN
    order_details od ON o.OrderNumber = od.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
WHERE
    s.Gender = 'F'
GROUP BY o.SalesChannel
ORDER BY o.SalesChannel;


-- Which is the total revenue by Product Category, considerating only the orders placed by male staff?

SELECT 
    p.ProductCategory,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM
    products p
        JOIN
    order_details od ON p.ProductKey = od.ProductKey
        JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
WHERE
    s.Gender = 'M'
GROUP BY p.ProductCategory
ORDER BY p.ProductCategory;


-- Rank all salesperson by Revenue. Show both the first and last name on one column.

SELECT
	CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
    SUM(od.Quantity * od.UnitPrice) AS PersonalRevenue
FROM
    order_details od
		JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
GROUP BY FullName
ORDER BY PersonalRevenue DESC;


-- Rank all salesperson by Revenue, showed as a percentage of total revenue. Show both the first and last name on one column.

-- 1st solution: using CTE

WITH TotBySalesperson AS (
SELECT
	CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
    SUM(od.Quantity * od.UnitPrice) AS PersonalRevenue
FROM
    order_details od
		JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
GROUP BY FullName
ORDER BY PersonalRevenue DESC
)
SELECT
	FullName,
    ROUND((PersonalRevenue / (SELECT SUM(Quantity * UnitPrice) FROM order_details)) * 100, 1) AS PtgPersonalRevenue
FROM
	TotBySalesperson
ORDER BY PtgPersonalRevenue DESC;

-- 2nd solution: No CTE

SELECT
	CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
    ROUND((SUM(od.Quantity * od.UnitPrice) / (SELECT SUM(Quantity * UnitPrice) FROM order_details)) * 100, 2) AS PtgPersonalRevenue
FROM
    order_details od
		JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
GROUP BY FullName
ORDER BY PtgPersonalRevenue DESC;


-- Which is the ATP (average ticket price) of each salesperson?

SELECT
	CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
    ROUND(SUM(od.Quantity * od.UnitPrice) / COUNT(DISTINCT(o.OrderNumber)), 2) AS ATP
FROM
    order_details od
		JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
GROUP BY FullName
ORDER BY ATP DESC;


-- Which is the the total Revenue of the TOP 3 salesperson?

WITH Top3Salesperson AS (
SELECT
	CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
    SUM(od.Quantity * od.UnitPrice) AS PersonalRevenue
FROM
    order_details od
		JOIN
    orders o ON od.OrderNumber = o.OrderNumber
        JOIN
    salesperson s ON o.SalespersonKey = s.SalespersonKey
GROUP BY FullName
ORDER BY PersonalRevenue DESC
LIMIT 3
)
SELECT
SUM(PersonalRevenue) AS Top3Revenue
FROM
Top3Salesperson;


-- Create a view that will show the product groups whith a cumulated revenue higher than one million (1.000.000).

CREATE OR REPLACE VIEW v_Prod_Group_Over_1000000 AS
SELECT 
    p.ProductGroup,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM
    products p
        JOIN
    order_details od ON p.ProductKey = od.ProductKey
GROUP BY p.ProductGroup
HAVING Revenue >= 1000000
ORDER BY Revenue DESC;


-- Create a procedure to know the name and cumulated revenue of the best salesperson at the moment of execution. Then call the procedure.

DROP PROCEDURE IF EXISTS BestCurrentSalesperson;

DELIMITER $$
CREATE PROCEDURE BestCurrentSalesperson()
BEGIN
	SELECT
		CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
		SUM(od.Quantity * od.UnitPrice) AS PersonalRevenue
	FROM
		order_details od
			JOIN
		orders o ON od.OrderNumber = o.OrderNumber
			JOIN
		salesperson s ON o.SalespersonKey = s.SalespersonKey
	GROUP BY FullName
	ORDER BY PersonalRevenue DESC
    LIMIT 1;
END$$
DELIMITER ;

CALL BestCurrentSalesperson;


-- Create a procedure to know the name and cumulated revenue of a salesperson at the moment of execution, by its Key Number (ID).

DROP PROCEDURE IF EXISTS SalespersonRevenueByKey;

DELIMITER $$
CREATE PROCEDURE SalespersonRevenueByKey(IN p_SalespersonKey INTEGER)
BEGIN
	SELECT
		s.SalespersonKey,
        CONCAT_WS(' ', s.FirstName, s.LastName) AS FullName,
		SUM(od.Quantity * od.UnitPrice) AS PersonalRevenue
	FROM
		order_details od
			JOIN
		orders o ON od.OrderNumber = o.OrderNumber
			JOIN
		salesperson s ON o.SalespersonKey = s.SalespersonKey
	WHERE s.SalespersonKey = p_SalespersonKey
    GROUP BY FullName
    ORDER BY PersonalRevenue DESC;
END$$
DELIMITER ;


-- Create a procedure that uses as parameters the first and the last name of an individual, and returns their Salesperson Key.

DROP PROCEDURE IF EXISTS SalespersonKeyByFullName;

DELIMITER $$
CREATE PROCEDURE SalespersonKeyByFullName(IN p_FirstName VARCHAR(255), IN p_LastName VARCHAR(255), OUT p_SalespersonKey INTEGER)
BEGIN
	SELECT
		s.SalespersonKey
	INTO p_SalespersonKey FROM
		Salesperson s
    WHERE
        s.FirstName = p_FirstName AND s.LastName = p_LastName;
END$$
DELIMITER ;

