USE JoinOptimizationLab;
GO

SELECT
    s.name,
    s.auto_created,
    s.user_created,
    s.no_recompute,
    sp.last_updated,
    sp.rows,
    sp.rows_sampled,
    sp.modification_counter
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties
(
    s.object_id,
    s.stats_id
) AS sp
WHERE s.object_id = OBJECT_ID('dbo.Orders')
  AND s.name = 'IX_Orders_CustomerID';
GO