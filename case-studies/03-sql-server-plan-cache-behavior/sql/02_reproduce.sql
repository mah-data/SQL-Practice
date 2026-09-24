/*
Case Study #03
Tracing SQL Server Plan Cache Behavior

02_reproduce.sql

Purpose:
Reproduce the initial observation where a query is executed
but its execution statistics are not immediately found by
a subsequent DMV query.

Important:
The target query is intentionally executed first.
The DMV query uses OPTION (RECOMPILE) so that the diagnostic
query itself does not create a reusable plan in Plan Cache.

Why OPTION (RECOMPILE)?
The purpose of this case study is to observe the target query's
Plan Cache behavior. If the diagnostic DMV query also creates
a reusable cached plan, it can add noise to the experiment and
potentially affect the small test environment's Plan Cache.

OPTION (RECOMPILE) forces the diagnostic statement to compile
for that execution instead of reusing a cached plan.

This option is applied only to the diagnostic query.
It is NOT applied to the target query.
*/

USE JoinOptimizationLab;
GO

-- Step 1: Clear the Plan Cache
DBCC FREEPROCCACHE;
GO

-- Step 2: Execute the target query
SELECT *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

/*
Step 3: Inspect execution statistics.

OPTION (RECOMPILE) is used deliberately on the diagnostic
statement.

RECOMPILE does NOT skip execution and does NOT mean that
no execution plan is created.

SQL Server still compiles and executes the statement for
the current execution. The difference is that the statement
does not reuse a previously cached plan for that execution.

The diagnostic query is a measurement tool, not the workload
being investigated. Therefore, RECOMPILE is used to avoid
reusing a cached plan for the diagnostic statement and to
reduce reusable-plan noise during the experiment.

Important:
RECOMPILE does not guarantee that the diagnostic statement
has zero impact on Plan Cache. It only changes the compilation
and reuse behavior of that statement.
*/

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