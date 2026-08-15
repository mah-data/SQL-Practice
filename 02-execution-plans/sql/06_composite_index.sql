/*
    SQL Server Execution Plans Lab
    Composite Index

    Purpose:
    Investigate composite indexes and understand
    how key column order affects index usage.
*/

USE ParameterSniffingLab;
GO

/*
    Step 1: Composite index with CustomerID first.
*/

CREATE INDEX IX_Orders_CustomerID_OrderDate
ON dbo.Orders(CustomerID, OrderDate);
GO

/*
    Step 2: Query using both key columns.
*/

SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10
  AND OrderDate = '2026-01-01';
GO

/*
    Step 3: Query using only the leading column.
*/

SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10;
GO

/*
    Step 4: Query using only the second key column.
*/

SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE OrderDate = '2026-01-01';
GO

/*
    Step 5: Create the same columns in reverse order
    for comparison.
*/

CREATE INDEX IX_Orders_OrderDate_CustomerID
ON dbo.Orders(OrderDate, CustomerID);
GO

/*
    Step 6: Execute the same query again and compare
    the execution plan and index usage.
*/

SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10
  AND OrderDate = '2026-01-01';
GO