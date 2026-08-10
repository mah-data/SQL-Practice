/*
    SQL Server Execution Plans Lab
    Setup Script

    Purpose:
    Create a test database and a skewed dataset
    for investigating execution plans and
    cardinality estimation.
*/

CREATE DATABASE ParameterSniffingLab;
GO

USE ParameterSniffingLab;
GO

CREATE TABLE dbo.Orders
(
    OrderID INT IDENTITY(1,1) NOT NULL,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_Orders
        PRIMARY KEY (OrderID)
);
GO