/*
    SQL Server Performance Case Study #02
    The Query Was Fast. The Application Was Slow.

    Purpose:
    Verify the database and table used for the blocking investigation.
*/

USE JoinOptimizationLab;
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NULL
BEGIN
    RAISERROR ('dbo.Orders does not exist in JoinOptimizationLab.', 16, 1);
    RETURN;
END;
GO

SELECT
    DB_NAME() AS DatabaseName,
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    OBJECT_NAME(object_id) AS TableName
FROM sys.tables
WHERE object_id = OBJECT_ID('dbo.Orders');
GO

SELECT TOP (1)
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
ORDER BY OrderID;
GO