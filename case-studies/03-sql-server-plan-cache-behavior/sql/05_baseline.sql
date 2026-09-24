/*
Case Study #03
Tracing SQL Server Plan Cache Behavior:
Compilation, Reuse, Eviction, and Performance Evidence

05_baseline.sql

Purpose:
Establish a clean baseline for the target statement before
testing repeated execution and intervening activity.

The baseline records:
    - Execution count
    - CPU time
    - Elapsed time
    - Logical reads
    - Query text

The target statement is identified by a unique marker.
*/

USE JoinOptimizationLab;
GO


/* =========================================================
   Step 1 — Clear Plan Cache
   ========================================================= */

DBCC FREEPROCCACHE;
GO


/* =========================================================
   Step 2 — Execute target statement once
   ========================================================= */


SELECT /* CASE03_TARGET */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO


/* =========================================================
   Step 3 — Capture execution statistics
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
WHERE st.text LIKE '%CASE03_TARGET%'
OPTION (RECOMPILE);
GO