/*
Case Study #03
Tracing SQL Server Plan Cache Behavior

01_setup.sql

Purpose:
Prepare the test environment for observing SQL Server
Plan Cache behavior.

This script does not perform the actual Plan Cache experiment.
*/

USE JoinOptimizationLab;
GO

-- Verify the test database
SELECT
    DB_NAME() AS database_name,
    @@SERVERNAME AS server_name;
GO

-- Verify the test table
SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    SUM(row_count) AS row_count
FROM sys.dm_db_partition_stats
WHERE object_id = OBJECT_ID('dbo.Orders')
  AND index_id IN (0, 1)
GROUP BY
    object_id;
GO

-- Verify the test column
SELECT
    c.name AS column_name,
    t.name AS data_type,
    c.max_length
FROM sys.columns AS c
JOIN sys.types AS t
    ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.Orders')
  AND c.name = 'CustomerID';
GO