/*
    SQL Server Execution Plans Lab
    Cardinality Estimation

    Purpose:
    Compare estimated rows with actual rows
    and observe the effect of statistics on
    the query optimizer.
*/

USE ParameterSniffingLab;
GO

-- CustomerID = 10
-- Expected result: 1 row
SELECT
    *
FROM dbo.Orders
WHERE CustomerID = 10;
GO

-- CustomerID = 1
-- Expected result: approximately 6.8 million rows
SELECT
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO