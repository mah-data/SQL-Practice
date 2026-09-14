/*
    SQL Server Performance Case Study #02
    The Query Was Fast. The Application Was Slow.

    Purpose:
    Reproduce a controlled blocking scenario.

    IMPORTANT:
    Run the BLOCKER section in one SSMS window
    and keep the transaction open.

    Run the BLOCKED QUERY section in a second SSMS window.
*/


/* =========================================================
   SESSION 1 - BLOCKER
   ========================================================= */

USE JoinOptimizationLab;
GO

BEGIN TRAN;

UPDATE dbo.Orders
SET Amount = Amount + 1
WHERE OrderID = 1;

-- Do NOT COMMIT or ROLLBACK yet.
-- The transaction must remain open for the blocking test.


/* =========================================================
   SESSION 2 - BLOCKED QUERY
   ========================================================= */

USE JoinOptimizationLab;
GO

SELECT *
FROM dbo.Orders
WHERE OrderID = 1;


/*
   Expected behavior:

   The SELECT should wait because Session 1
   holds a lock on the target row.
*/