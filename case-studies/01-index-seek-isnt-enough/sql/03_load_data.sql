USE JoinOptimizationLab;
GO

/*
    CASE STUDY #01
    ----------------
    Data Distribution

    CustomerID = 1  -> 6,817,321 rows
    CustomerID = 2  -> 1 row
    CustomerID = 3  -> 1 row
    CustomerID = 4  -> 1 row
    CustomerID = 5  -> 1 row
    CustomerID = 6  -> 1 row
    CustomerID = 7  -> 1 row
    CustomerID = 8  -> 1 row
    CustomerID = 9  -> 1 row
    CustomerID = 10 -> 1 row

    Total = 6,817,330 rows
*/

-- Generate the highly skewed portion
INSERT INTO dbo.Orders
(
    OrderID,
    CustomerID,
    OrderDate,
    Amount
)
SELECT TOP (6817321)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
    1,
    DATEADD(
        DAY,
        ABS(CHECKSUM(NEWID())) % 3650,
        '2016-01-01'
    ),
    CAST(
        (ABS(CHECKSUM(NEWID())) % 100000) / 100.0
        AS DECIMAL(18,2)
    )
FROM sys.all_objects AS A
CROSS JOIN sys.all_objects AS B;
GO

-- Add one row for CustomerID 2 through 10
INSERT INTO dbo.Orders
(
    OrderID,
    CustomerID,
    OrderDate,
    Amount
)
VALUES
    (6817322, 2,  '2026-01-01', 100.00),
    (6817323, 3,  '2026-01-01', 100.00),
    (6817324, 4,  '2026-01-01', 100.00),
    (6817325, 5,  '2026-01-01', 100.00),
    (6817326, 6,  '2026-01-01', 100.00),
    (6817327, 7,  '2026-01-01', 100.00),
    (6817328, 8,  '2026-01-01', 100.00),
    (6817329, 9,  '2026-01-01', 100.00),
    (6817330, 10, '2026-01-01', 100.00);
GO