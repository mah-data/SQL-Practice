/*
    SQL Server Execution Plans Lab
    Covering Index

    Purpose:
    Investigate Key Lookup and understand
    how a covering index can eliminate
    additional lookups.
*/

USE ParameterSniffingLab;
GO

/*
    Step 1: Create a non-covering index
    on CustomerID.
*/

CREATE INDEX IX_Orders_CustomerID
ON dbo.Orders(CustomerID);
GO

/*
    Step 2: Query CustomerID and Amount.

    The index can be used to find the rows
    by CustomerID, but Amount is not part
    of the index.

    Check the Actual Execution Plan for
    a Key Lookup.
*/

SELECT
    CustomerID,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10;
GO

/*
    Step 3: Create a covering index.

    Amount is included in the index so the
    query can be satisfied directly from
    the index.
*/

CREATE INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders(CustomerID)
INCLUDE (Amount);
GO

/*
    Step 4: Execute the same query again.

    Compare the Actual Execution Plan
    with the previous execution.

    The covering index can eliminate
    the Key Lookup.
*/

SELECT
    CustomerID,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10;
GO