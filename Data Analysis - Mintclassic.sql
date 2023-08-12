use mintclassics;


-- REMOVING NULL
select *
from products
where productCode = null;

delete from products
where productCode = null ;
 
 
-- 1. INDENTIFY SLOW MOVING PRODUCTS 

select productCode, productName, quantityInStock
from products
where quantityInStock > 0 and quantityInStock < 1000;
-- (Using this query to identify products with low stock levels (between 1 and 999 units) that are not selling quickly. These products could be considered for discontinuation or promotion to clear out inventory)

-- 2. DISCOUNTING UNPOPULAR ITEM/ PRODUCTS

update products
set buyprice = buyprice * 0.80
where quantityInStock > 0 and quantityInStock < 500;
-- (This query reduces the buy price of products with very low stock levels (less than 500 units) by 20%. Lowering the price can encourage customers to purchase these products and reduce inventory)

-- 3. ANALYZE HISTORICAL DEMAND

select p.productCode, p.productName, sum(od.quantityOrdered) as totalQuantityOrdered
from products p
join orderdetails od
	on p.productCode = od.productCode
group by p.productCode, p.productName
order by totalQuantityOrdered desc
limit 10;
-- (By analyzing historical sales data, we can identify which products have consistently high demand. We can focus on these products and ensure sufficient stock levels for timely customer service.)

-- 4. IMPLEMENTING JIT(JUST-IN-TIME) REORDERING
select p.productCode, p.productName, p.quantityInStock, od.quantityOrdered, ((1000- p.quantityInStock) - od.quantityOrdered ) as ReorderQuantity
from products p
join orderdetails od
	on p.productCode = od.productCode
join orders o
	on od.orderNumber = o.orderNumber
where p.quantityInStock <= 1000
order by o.orderDate;
-- (This query identifies products with low stock levels (1000 units or fewer) and retrieves their recent orders. By monitoring these orders, we can implement a just-in-time reordering strategy to replenish stock only when necessary, minimizing excess inventory.)

-- 5. CONSOLIDATE PRODUCT LINES
select productLine, count(productCode) as totalProducts
from products 
group by productLine
order by totalProducts asc;
-- (This will consolidate or phase out product lines with a low number of products. This query helps us to identify product lines with fewer offerings, which can streamline inventory management.)

-- 6. ANALYZING CUSTOMER PURCHASE PATTERNS
select c.customerNumber, c.customerName, count(o.orderNumber) as totalOrders
from customers c
join orders o 
	on c.customerNumber = o.customerNumber
group by c.customerNumber, c.customerName
order by totalOrders desc;
-- (Analyzing which customers place the most orders. Prioritizing high-volume customers for timely service while potentially adjusting inventory for low-volume customers.)

-- 7. MONITORING SALES REPRESENATIVES PERFORMANCE
select e.employeeNumber, e.firstName, e.lastName, count(o.orderNumber) as totalOrders
from employees e
join customers c 
	on e.employeeNumber = c.salesRepEmployeeNumber
join orders o 
	on c.customerNumber = o.customerNumber
group by e.employeeNumber, e.firstName, e.lastName
order by totalOrders desc;
-- (Identifying which sales representatives handle the most orders. This information can guide resource allocation and ensure efficient customer service.)


------------------------------------------------------------------------------------------- 
/*
Question 1: Where are items stored, and if they were rearranged, could a warehouse be eliminated?
*/
SELECT w.warehouseCode, w.warehouseName, p.productCode, p.productName, p.quantityInStock
FROM warehouses w
JOIN products p ON w.warehouseCode = p.warehouseCode
ORDER BY w.warehouseCode, p.quantityInStock;
-- This query retrieves information about products stored in each warehouse and their current stock levels. By analyzing the distribution of products and their quantities across warehouses, you can identify opportunities for rearrangement or consolidation.

/* 
Question 2: How are inventory numbers related to sales figures? Do the inventory counts seem appropriate for each item?
*/
SELECT p.productCode, p.productName, p.quantityInStock, SUM(od.quantityOrdered) AS totalQuantityOrdered
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName, p.quantityInStock
ORDER BY totalQuantityOrdered DESC;
-- This query joins product inventory data with sales data to compare inventory levels with total quantity ordered. By identifying products with low inventory relative to their sales, you can make informed decisions about adjusting stock levels.

/*
Question 3: Are we storing items that are not moving? Are any items candidates for being dropped from the product line?
*/
SELECT p.productCode, p.productName, p.quantityInStock, od.orderNumber
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
WHERE od.orderNumber IS NULL or od.orderNumber= 0
ORDER BY p.quantityInStock DESC;
-- This query identifies products that have not been sold (no corresponding orders) and have high quantities in stock. These products may be candidates for removal from the product line or special promotions to clear out inventory.

-------------------------------------------------------------------------------------------

/* 
DETERMINING IMPORTANT FACTORS FOR INVENTORY REORGANIZATION/ REDUCTION
*/
-- 1. Calculate the inventory turnover rate for each product & Identify products with lower inventory turnover rate
SELECT p.productCode, p.productName, 
       sum(od.quantityOrdered) AS totalQuantityOrdered,
       p.quantityInStock,
       sum(od.quantityOrdered) / p.quantityInStock AS inventoryTurnover
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName, p.quantityInStock
HAVING inventoryTurnover < 0.5
ORDER BY inventoryTurnover DESC; 

/*
Provide analytic insights and data-driven recommendations
*/
-- Find products with no recent sales (potential candidates for removal):
SELECT p.productCode, p.productName
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
WHERE od.orderNumber IS NULL;

-- Identify customers with the highest number of orders
SELECT c.customerNumber, c.customerName, COUNT(o.orderNumber) AS totalOrders
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY totalOrders DESC;

-- Explore the relationship between product lines and sales
SELECT p.productLine, COUNT(DISTINCT od.orderNumber) AS totalOrders,
       SUM(od.quantityOrdered) AS totalQuantityOrdered
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productLine
ORDER BY totalOrders DESC;


-------------------------------------------------------------------------------------------

-- 	IDENTIFYING SLOW-MOVING PRODUCTS
SELECT p.productCode, p.productName, p.quantityInStock,
       SUM(od.quantityOrdered) AS totalQuantityOrdered,
       AVG(p.quantityInStock) AS avgInventory,
       SUM(od.quantityOrdered) / AVG(p.quantityInStock) AS inventoryTurnover
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
LEFT JOIN orders o ON od.orderNumber = o.orderNumber
WHERE o.orderDate >= (SELECT DATE_SUB(MAX(orderDate), INTERVAL 6 MONTH) FROM orders)
      OR o.orderDate IS NULL
GROUP BY p.productCode, p.productName, p.quantityInStock
HAVING inventoryTurnover < 0.5
ORDER BY inventoryTurnover ASC;
-- In summary, this query helps to identify products that have been slow-moving within the last 6 months from the latest order date. These products may be candidates for further analysis and potential removal from the inventory or other inventory management strategies. The query ensures that the business can make informed decisions about reducing inventory and optimizing warehouse space while maintaining timely service to customers.


-- ANALYZING SEASONAL DEMAND
SELECT p.productCode, p.productName,
       MONTH(orderDate) AS month,
       SUM(quantityOrdered) AS totalQuantityOrdered
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON od.orderNumber = o.orderNumber
GROUP BY p.productCode, p.productName, month
ORDER BY p.productCode, month;
-- The query provides a comprehensive overview of how products perform in terms of monthly sales. It helps identify seasonal patterns and trends, which can aid in making informed decisions regarding inventory management, marketing strategies, and potential adjustments to product offerings. This analysis can contribute to optimizing inventory levels and ensuring timely customer service while minimizing carrying costs for Mint Classics Company.

-- ASSESING WAREHOUSE UTILIZATION
SELECT p.productLine,
       SUM(p.quantityInStock) AS totalInventory,
       AVG(p.quantityInStock) AS avgInventory,
       COUNT(DISTINCT p.productCode) AS totalProducts,
       COUNT(DISTINCT w.warehouseCode) AS totalWarehouses
FROM products p
JOIN warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY p.productLine
ORDER BY totalInventory DESC;
-- In summary, this query generates a report that outlines the total and average inventory levels, total distinct products, and total distinct warehouses for each product line within Mint Classics Company. The information obtained from this summary can guide decisions related to inventory optimization, such as identifying overstocked or underutilized product lines, and aid in making strategic choices for reducing inventory and potentially closing storage facilities.

-- WAREHOUSE CLOSURE CONSIDERATION
SELECT w.warehouseCode,
       SUM(p.quantityInStock) AS totalInventory,
       AVG(p.quantityInStock) AS avgInventory,
       COUNT(DISTINCT p.productCode) AS totalProducts
FROM products p
JOIN warehouses w ON p.warehouseCode = w.warehouseCode
WHERE w.warehouseCode = 'a' -- Adjust to the warehouse you're considering
GROUP BY w.warehouseCode;
-- In summary, the query calculates and presents key inventory statistics for a particular warehouse ('a'). It provides insights into the total inventory, average inventory, and total distinct products available in the specified warehouse. This information can be valuable for assessing the inventory situation and making informed decisions related to inventory reduction or reorganization.

