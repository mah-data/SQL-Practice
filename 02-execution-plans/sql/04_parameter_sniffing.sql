/*
    SQL Server Execution Plans Lab
    Parameter Sniffing

    Purpose:
    Investigate parameter-sensitive query behavior,
    plan compilation, and plan reuse.
*/

USE ParameterSniffingLab;
GO

-- Create a stored procedure with a parameter
CREATE OR ALTER PROCEDURE dbo.GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT COUNT(*) AS OrderCount
    FROM dbo.Orders
    WHERE CustomerID = @CustomerID;
END;
GO

-- Clear cached plans
DBCC FREEPROCCACHE;
GO

-- First execution
EXEC dbo.GetOrdersByCustomer
    @CustomerID = 10;
GO

-- Second execution with a different parameter
EXEC dbo.GetOrdersByCustomer
    @CustomerID = 1;
GO



/*
    Parameter Sensitive Plan Optimization (PSPO)
    
    SQL Server 2022 can create multiple query variants
    for parameter-sensitive queries when compatibility
    level is 160 or higher.
*/

-- Check compatibility level
SELECT
    name,
    compatibility_level
FROM sys.databases
WHERE name = 'ParameterSniffingLab';
GO

-- Check PSPO configuration
SELECT
    name,
    value
FROM sys.database_scoped_configurations
WHERE name = 'PARAMETER_SENSITIVE_PLAN_OPTIMIZATION';
GO

/*
    Data distribution used in this lab:

    CustomerID = 1  -> 6,817,321 rows
    CustomerID = 10  -> 1 row

    This skewed distribution can cause
    parameter-sensitive plan behavior.
*/

/*
    With PSPO enabled, SQL Server may create
    multiple query variants for different
    cardinality ranges.

    Query Store can be used to investigate
    these variants.
*/

-- Query Store: find PSPO variants
SELECT
    q.query_id,
    p.plan_id,
    qt.query_sql_text
FROM sys.query_store_query AS q
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt
    ON q.query_text_id = qt.query_text_id
WHERE qt.query_sql_text LIKE '%PLAN PER VALUE%'
ORDER BY q.query_id, p.plan_id;
GO
