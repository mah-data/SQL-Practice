/*
Case Study #03
Tracing SQL Server Plan Cache Behavior

03_trace.sql

Purpose:
Trace the target query across SQL Server execution statistics
and Plan Cache metadata.

The target query:
    SELECT *
    FROM dbo.Orders
    WHERE CustomerID = 1;

This script does not modify the workload.
The diagnostic statements use RECOMPILE so that they
do not rely on previously cached diagnostic plans.
*/

USE JoinOptimizationLab;
GO

/* =========================================================
   1. Execution Statistics
   ========================================================= */

SELECT
    qs.execution_count,
    qs.total_worker_time,
    qs.total_elapsed_time,
    qs.total_logical_reads,
    qs.total_logical_writes,
    st.text AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.text LIKE '%CustomerID%'
OPTION (RECOMPILE);
GO


/* =========================================================
   2. Plan Cache Metadata
   ========================================================= */

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.dbid,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CustomerID%'
OPTION (RECOMPILE);
GO