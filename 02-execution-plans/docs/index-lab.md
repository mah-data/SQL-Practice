# Index Lab

## Objective

Investigate how different index structures affect SQL Server execution plans and query performance.

The lab uses the `dbo.Orders` table in the `ParameterSniffingLab` database.

---

## 1. Clustered Index

The `Orders` table has a primary key on `OrderID`:

```sql
CONSTRAINT PK_Orders
    PRIMARY KEY (OrderID)

The primary key is implemented as the clustered index in this lab.

A clustered index determines the physical order of the data rows in the table.

2. Nonclustered Index

A nonclustered index was created on CustomerID:

CREATE INDEX IX_Orders_CustomerID
ON dbo.Orders(CustomerID);

This index allows SQL Server to locate rows based on CustomerID without scanning the entire table.

For a selective value such as CustomerID = 10, SQL Server can use an Index Seek.

3. Key Lookup

The query requested Amount in addition to CustomerID:

SELECT
    CustomerID,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10;

The nonclustered index contains CustomerID, but it does not contain Amount.

SQL Server may therefore use a Key Lookup to retrieve the missing column from the clustered index.

The execution plan can look like:

Index Seek → Key Lookup

4. Covering Index

A covering index was created:

CREATE INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders(CustomerID)
INCLUDE (Amount);

CustomerID is the key column and Amount is an included column.

The query can now be satisfied directly from the nonclustered index.

This can eliminate the Key Lookup:

Index Seek → Result

A covering index can therefore reduce additional lookups for queries that frequently request the included columns.

5. Composite Index

A composite index contains multiple key columns:

CREATE INDEX IX_Orders_CustomerID_OrderDate
ON dbo.Orders(CustomerID, OrderDate);

The key column order is:

CustomerID
OrderDate

The order is important because CustomerID is the leading key.

6. Column Order

The following index has a different structure:

CREATE INDEX IX_Orders_OrderDate_CustomerID
ON dbo.Orders(OrderDate, CustomerID);

Although both indexes contain the same columns, they are not equivalent.

The leading column affects how SQL Server can efficiently navigate the index.

Therefore, index key order should be chosen according to query predicates and workload.

7. Execution Plan Comparison

The lab compares execution plans for different index designs.

Important operators and concepts include:

Index Seek
Index Scan
Key Lookup
Predicate
Seek Predicate
Leading Key
Included Columns

The objective is not simply to create indexes, but to understand why SQL Server chooses a particular access path.

Key Findings
A clustered index stores the table data according to its key.
A nonclustered index provides an additional access path to the data.
A Key Lookup can occur when a nonclustered index does not contain all required columns.
A covering index can eliminate the Key Lookup.
A composite index can contain multiple key columns.
The order of columns in a composite index matters.
Index design should be based on actual query patterns and execution plans.