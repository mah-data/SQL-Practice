/*
    SQL Server Performance Case Study #02
    The Query Was Fast. The Application Was Slow.

    Purpose:
    Verify the performance of the target query when
    no blocking exists.

    Evidence captured:
    1. Actual Execution Plan
    2. CPU time
    3. Elapsed time
    4. Logical reads
    5. Physical reads
    6. Scan count
    7. Rows returned
*/


USE JoinOptimizationLab;
GO


/* =========================================================
   1. VERIFY DATABASE
   ========================================================= */

SELECT
    DB_NAME() AS DatabaseName;
GO


/* =========================================================
   2. VERIFY TARGET ROW
   ========================================================= */

SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE OrderID = 1;
GO


/* =========================================================
   3. ENABLE ACTUAL EXECUTION PLAN
   =========================================================

   In SSMS:

       Ctrl + M

   Then execute the baseline query below.

   The actual execution plan should show:

       Clustered Index Seek
           |
           └── PK_Orders

   Plan cardinality observed in the lab:

       Estimated Number of Rows = 1
       Actual Number of Rows    = 1
*/


/* =========================================================
   4. ENABLE PERFORMANCE STATISTICS
   ========================================================= */

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


/* =========================================================
   5. BASELINE PERFORMANCE TEST
   ========================================================= */

SELECT
    *
FROM dbo.Orders
WHERE OrderID = 1;
GO


/* =========================================================
   6. DISABLE PERFORMANCE STATISTICS
   ========================================================= */

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/*
=============================================================
OBSERVED BASELINE EVIDENCE
=============================================================

Query:

    SELECT *
    FROM dbo.Orders
    WHERE OrderID = 1;


STATISTICS TIME:

    CPU time    = 0 ms
    Elapsed time = 1 ms


STATISTICS IO:

    Table 'Orders'

    Scan count      = 0
    Logical reads   = 2
    Physical reads  = 0


RESULT:

    1 row returned


EXECUTION PLAN:

    Clustered Index Seek
        Object = dbo.Orders
        Index  = PK_Orders


PLAN CARDINALITY:

    Estimated Number of Rows = 1
    Actual Number of Rows    = 1


INTERPRETATION:

    The query performs efficiently when no blocking exists.

    The execution plan shows a direct Clustered Index Seek
    on the primary key.

    The query requires only 2 logical reads and approximately
    1 ms elapsed time in this lab environment.

    Therefore, the query itself does not show evidence of
    an inefficient access path or excessive I/O.
*/


/*
=============================================================
BLOCKING EVIDENCE
=============================================================

Blocked Session:
    63

Blocking Session:
    65

Status:
    suspended

Wait Type:
    LCK_M_S

Observed Wait Time:
    4452 ms

Wait Resource:
    KEY: 8:72057594045792256 (1b7fe5b8af93)

Command:
    SELECT


BLOCKER SESSION:

    Session ID:
        65

    Status:
        sleeping

    Open Transaction Count:
        1

    Login:
        sa

    Program:
        Microsoft SQL Server Management Studio - Query


BLOCKER TRANSACTION:

    Transaction ID:
        246093

    Transaction Begin Time:
        2026-09-14 23:46:20.777

    Transaction Type:
        1

    Transaction State:
        2


BLOCKING SQL:

    BEGIN TRAN;

    UPDATE dbo.Orders
    SET Amount = Amount + 1
    WHERE OrderID = 1;


RESOLUTION:

    ROLLBACK;


RESULT:

    Session 63 was released and the SELECT completed.
*/


/*
=============================================================
IMPORTANT NOTE ABOUT WAIT_TIME
=============================================================

    4452 ms is the DMV wait_time observed while the request
    was blocked.

    It is NOT the STATISTICS TIME elapsed time of the query.

    Therefore:

        Blocking wait_time = 4452 ms

    and:

        Normal query elapsed time = 1 ms

    must be reported as two different measurements.
*/


/*
=============================================================
FINAL CONCLUSION
=============================================================

NORMAL EXECUTION:

    CPU time       = 0 ms
    Elapsed time   = 1 ms
    Logical reads  = 2
    Physical reads = 0
    Scan count     = 0
    Rows returned  = 1

    Execution Plan:
        Clustered Index Seek
        PK_Orders


BLOCKING:

    Blocked Session  = 63
    Blocking Session = 65
    Wait Type        = LCK_M_S
    Wait Time        = 4452 ms


ROOT CAUSE:

    Session 65 kept an open transaction after updating
    dbo.Orders.

    The transaction remained open while the session was
    sleeping, so the lock remained held.

    Session 63 therefore had to wait for the required lock.


RESOLUTION:

    ROLLBACK released the transaction and the lock.

    Session 63 then completed successfully.


CASE STUDY CONCLUSION:

    The query was fast.

    The observed delay was caused by blocking, not by
    an inefficient execution plan or excessive I/O.
=============================================================
*/