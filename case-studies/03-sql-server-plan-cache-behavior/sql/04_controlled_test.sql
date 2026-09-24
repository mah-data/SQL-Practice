/*
Case Study #03
Tracing SQL Server Plan Cache Behavior:
Compilation, Reuse, Eviction, and Performance Evidence

04_controlled_test.sql

Purpose:
Document the controlled experiments used to observe SQL Server
Plan Cache behavior.

Tests:

    Test 1 - Single Execution
    Test 2 - Repeated Execution and Plan Reuse
    Test 3 - Intervening Ad hoc Activity
    Test 4 - Time-Based Plan Cache Observation

The experiments measure observable behavior in the test
environment.

They do not establish a fixed Plan Cache timeout or prove a
specific eviction mechanism from elapsed time alone.
*/


USE JoinOptimizationLab;
GO


/* =========================================================
   TEST 1
   Single Execution
   =========================================================

   Purpose:
   Observe the initial Plan Cache entry after one execution.
*/

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST1 */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

SELECT
    qs.execution_count,
    qs.total_worker_time,
    qs.total_elapsed_time,
    qs.total_logical_reads,
    qs.total_logical_writes,
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
LEFT JOIN sys.dm_exec_cached_plans AS cp
    ON qs.plan_handle = cp.plan_handle
WHERE st.text LIKE '%CASE03_TEST1%'
OPTION (RECOMPILE);
GO


/* =========================================================
   TEST 2
   Repeated Execution and Plan Reuse
   =========================================================

   Purpose:
   Verify that repeated executions can reuse the cached plan.
*/

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST2 */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

SELECT /* CASE03_TEST2 */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

SELECT /* CASE03_TEST2 */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

SELECT
    qs.execution_count,
    qs.total_worker_time,
    qs.total_elapsed_time,
    qs.total_logical_reads,
    qs.total_logical_writes,
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
LEFT JOIN sys.dm_exec_cached_plans AS cp
    ON qs.plan_handle = cp.plan_handle
WHERE st.text LIKE '%CASE03_TEST2%'
OPTION (RECOMPILE);
GO


/* =========================================================
   TEST 3
   Intervening Ad hoc Activity
   =========================================================

   Purpose:
   Observe whether several intervening Ad hoc statements
   cause the target plan to disappear from Plan Cache.
*/

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST3 */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

SELECT *
FROM dbo.Customers
WHERE CustomerID = 1;
GO

SELECT *
FROM dbo.Customers
WHERE CustomerID = 2;
GO

SELECT *
FROM dbo.Customers
WHERE CustomerID = 3;
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST3%'
OPTION (RECOMPILE);
GO


/* =========================================================
   TEST 4
   Time-Based Plan Cache Observation
   =========================================================

   Controlled observations performed separately:

       10 seconds  -> Plan remained
       20 seconds  -> Plan remained
       30 seconds  -> Plan remained
       40 seconds  -> Plan not observed
       50 seconds  -> Plan not observed

   These observations do not establish a fixed timeout.
*/


/* ---------------------------------------------------------
   10 seconds
   --------------------------------------------------------- */

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST4_10S */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

WAITFOR DELAY '00:00:10';
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST4_10S%'
OPTION (RECOMPILE);
GO


/* ---------------------------------------------------------
   20 seconds
   --------------------------------------------------------- */

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST4_20S */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

WAITFOR DELAY '00:00:20';
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST4_20S%'
OPTION (RECOMPILE);
GO


/* ---------------------------------------------------------
   30 seconds
   --------------------------------------------------------- */

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST4_30S */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

WAITFOR DELAY '00:00:30';
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST4_30S%'
OPTION (RECOMPILE);
GO


/* ---------------------------------------------------------
   40 seconds
   --------------------------------------------------------- */

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST4_40S */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

WAITFOR DELAY '00:00:40';
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST4_40S%'
OPTION (RECOMPILE);
GO


/* ---------------------------------------------------------
   50 seconds
   --------------------------------------------------------- */

DBCC FREEPROCCACHE;
GO

SELECT /* CASE03_TEST4_50S */
    *
FROM dbo.Orders
WHERE CustomerID = 1;
GO

WAITFOR DELAY '00:00:50';
GO

SELECT
    cp.usecounts,
    cp.objtype,
    cp.cacheobjtype,
    cp.size_in_bytes,
    st.text AS query_text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%CASE03_TEST4_50S%'
OPTION (RECOMPILE);
GO