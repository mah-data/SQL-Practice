/*
    SQL Server Execution Plans Lab
    Statistics Investigation

    Purpose:
    Inspect statistics, compare sampled statistics
    with FULLSCAN, and observe the effect on
    cardinality estimation.
*/

USE ParameterSniffingLab;
GO

-- Check existing statistics
SELECT
    name,
    stats_id,
    auto_created,
    user_created,
    has_filter
FROM sys.stats
WHERE object_id = OBJECT_ID('dbo.Orders');
GO

-- Inspect statistics properties
SELECT
    s.name AS StatisticsName,
    sp.last_updated,
    sp.rows,
    sp.rows_sampled
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(
    s.object_id,
    s.stats_id
) AS sp
WHERE s.object_id = OBJECT_ID('dbo.Orders');
GO

-- Display histogram
DBCC SHOW_STATISTICS
(
    'dbo.Orders',
    'IX_Orders_CustomerID'
);
GO

-- Refresh statistics using FULLSCAN
UPDATE STATISTICS dbo.Orders
IX_Orders_CustomerID
WITH FULLSCAN;
GO

-- Verify statistics after FULLSCAN
SELECT
    s.name AS StatisticsName,
    sp.last_updated,
    sp.rows,
    sp.rows_sampled
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(
    s.object_id,
    s.stats_id
) AS sp
WHERE s.object_id = OBJECT_ID('dbo.Orders');
GO