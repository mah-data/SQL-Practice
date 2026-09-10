USE JoinOptimizationLab;
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
    OrderID    BIGINT NOT NULL,
    CustomerID INT NOT NULL,
    OrderDate  DATE NOT NULL,
    Amount     DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_Orders
        PRIMARY KEY CLUSTERED (OrderID)
);
GO