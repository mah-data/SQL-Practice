USE JoinOptimizationLab;
GO

/*
Day 31 - Join Optimization
Purpose:
Analyze Nested Loops, Hash Match, and Merge Join
using SQL Server Execution Plans.
*/

-- 1. Nested Loops
SELECT
    o.OrderID,
    o.CustomerID,
    c.CustomerName
FROM dbo.Orders AS o
INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID
WHERE o.CustomerID = 10;
GO


-- 2. Merge Join
SELECT
    o.OrderID,
    o.CustomerID,
    c.CustomerName
FROM dbo.Orders AS o
INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID;
GO


-- 3. Hash Match
SELECT
    o.OrderID,
    o.CustomerID,
    c.CustomerName
FROM dbo.Orders AS o
INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID
OPTION (HASH JOIN);
GO


-- 4. Cross Join experiment
SELECT
    o.OrderID,
    o.CustomerID,
    c.CustomerName
FROM dbo.Orders AS o
CROSS JOIN dbo.Customers AS c;
GO
