/*
    SQL Server Execution Plans Lab
    Parameter Sniffing

    Purpose:
    Investigate parameter-sensitive query behavior,
    plan compilation, and plan reuse.
*/

USE ParameterSniffingLab;
GO

-- Create a stored procedure with a parameter
CREATE OR ALTER PROCEDURE dbo.GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT COUNT(*) AS RowCount
    FROM dbo.Orders
    WHERE CustomerID = @CustomerID;
END;
GO

-- Clear cached plans
DBCC FREEPROCCACHE;
GO

-- First execution
EXEC dbo.GetOrdersByCustomer
    @CustomerID = 10;
GO

-- Second execution with a different parameter
EXEC dbo.GetOrdersByCustomer
    @CustomerID = 1;
GO