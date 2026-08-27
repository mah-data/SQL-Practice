#  Index Access Path Optimization

## Objective

Analyze SQL Server index access paths and understand:

- Clustered Index Scan
- Index Seek
- Key Lookup
- Covering Index
- Estimated Number of Rows
- Actual Number of Rows
- Actual Number of Rows Read
- Logical Reads
- Optimizer cost-based decisions

The goal is to understand how index design can influence the execution plan without forcing SQL Server to use a specific access path.

---

## 1. Initial Execution Plan

### Orders

| Property | Value |
|---|---|
| Physical Operation | Clustered Index Scan |
| Object | `[JoinOptimizationLab].[dbo].[Orders].[PK_Orders] [o]` |
| Predicate | `[JoinOptimizationLab].[dbo].[Orders].[CustomerID] as [o].[CustomerID]=(10)` |
| Estimated Number of Rows for All Executions | 10 |
| Actual Number of Rows | 10 |
| Actual Number of Rows Read | 1010 |
| Operator Cost (%) | 0.007356 (66%) |

### Customers

| Property | Value |
|---|---|
| Physical Operation | Index Seek |
| Actual Number of Rows | 1 |
| Actual Number of Rows Read | 1 |
| Operator Cost (%) | 0.0032831 (29%) |

### Observation

SQL Server correctly estimated the number of rows returned:

```text
Estimated = 10
Actual    = 10
```

However, the Clustered Index Scan read 1010 rows to return 10 rows.

Therefore, the main issue was not incorrect cardinality estimation.

---

## 2. Nonclustered Index Experiment

Created:

```sql
CREATE INDEX IX_Orders_CustomerID
ON dbo.Orders (CustomerID);
```

The index was tested using an Index Hint.

### Orders

| Property | Value |
|---|---|
| Physical Operation | Index Seek |
| Object | `[JoinOptimizationLab].[dbo].[Orders].[IX_Orders_CustomerID] [o]` |
| Actual Number of Rows | 10 |
| Actual Number of Rows Read | 10 |

### Key Lookup

| Property | Value |
|---|---|
| Physical Operation | Key Lookup |
| Object | `[JoinOptimizationLab].[dbo].[Orders].[PK_Orders] [o]` |

The Key Lookup occurred because the nonclustered index contained `CustomerID`, while the query also required `OrderID` and `OrderDate`.

### Execution Path

```text
IX_Orders_CustomerID
        ↓
    Index Seek
        ↓
     10 rows
        ↓
    Key Lookup
        ↓
     PK_Orders
```

### STATISTICS IO

| Table | Logical Reads | Physical Reads |
|---|---:|---:|
| Orders | 22 | 0 |
| Customers | 2 | 0 |

### Observation

The Index Seek reduced Rows Read:

```text
1010 → 10
```

However, the Key Lookup introduced additional I/O.

Therefore:

> An Index Seek is not automatically better than an Index Scan.

The complete execution path and total I/O must be considered.

---

## 3. Covering Index Experiment

Created:

```sql
CREATE INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders (CustomerID)
INCLUDE (OrderID, OrderDate);
```

### Index Design

| Type | Columns |
|---|---|
| Key Column | `CustomerID` |
| Included Columns | `OrderID`, `OrderDate` |

`CustomerID` was used as the key because it was used for filtering and joining.

`OrderID` and `OrderDate` were included because they were required by the query output.

### Orders

| Property | Value |
|---|---|
| Physical Operation | Index Seek |
| Object | `[JoinOptimizationLab].[dbo].[Orders].[IX_Orders_CustomerID_Covering] [o]` |
| Actual Number of Rows | 10 |
| Actual Number of Rows Read | 10 |
| Key Lookup | None |

### Execution Path

```text
IX_Orders_CustomerID_Covering
              ↓
          Index Seek
              ↓
           10 rows
              ↓
            Output
```

The query could retrieve all required `Orders` columns directly from the covering index.

Therefore, SQL Server no longer needed to perform a Key Lookup against `PK_Orders`.

---

## 4. Performance Comparison

| Scenario | Access Path | Rows Read | Key Lookup | Orders Logical Reads |
|---|---|---:|---|---:|
| Initial | Clustered Index Scan | 1010 | No | 7 |
| Simple Index | Index Seek | 10 | Yes | 22 |
| Covering Index | Index Seek | 10 | No | 2 |

### Final STATISTICS IO

| Table | Logical Reads | Physical Reads |
|---|---:|---:|
| Orders | 2 | 0 |
| Customers | 2 | 0 |

The covering index reduced:

```text
Orders Logical Reads: 7 → 2
Rows Read:            1010 → 10
Key Lookup:           Yes → No
```

---

## 5. Optimizer Behavior

The SQL Server Query Optimizer initially selected the Clustered Index Scan.

The estimated result cardinality was:

```text
10 rows
```

The actual result was:

```text
10 rows
```

Therefore:

```text
Estimated Rows = Actual Rows
```

Cardinality estimation was accurate.

The optimizer does not simply choose the plan with the smallest number of rows read.

It evaluates the estimated cost of alternative execution plans using its cost model.

The simple nonclustered index produced an Index Seek but also introduced a Key Lookup.

The covering index eliminated the Key Lookup and reduced logical reads.

After the covering index was created and the simple index was removed, SQL Server selected the covering index automatically without an Index Hint.

---

## 6. Index Cleanup

The experimental nonclustered index was removed:

```sql
DROP INDEX IX_Orders_CustomerID
ON dbo.Orders;
```

Final indexes on `Orders`:

```text
PK_Orders
IX_Orders_CustomerID_Covering
```

The primary key was not modified.

---

## 7. Final Execution Plan

The final query was executed without an Index Hint.

SQL Server selected:

```text
IX_Orders_CustomerID_Covering
        ↓
    Index Seek
        ↓
     10 rows
        ↓
     Output
```

### Final Orders Properties

| Property | Value |
|---|---|
| Physical Operation | Index Seek |
| Object | `[JoinOptimizationLab].[dbo].[Orders].[IX_Orders_CustomerID_Covering] [o]` |
| Actual Number of Rows | 10 |
| Actual Number of Rows Read | 10 |
| Key Lookup | None |

This confirmed that SQL Server could automatically select the improved index design.

---

## 8. STATISTICS IO / TIME

Final test:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    c.CustomerName
FROM dbo.Orders AS o
INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID
WHERE o.CustomerID = 10;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

Final observed values:

```text
Orders:
logical reads = 2
physical reads = 0

Customers:
logical reads = 2
physical reads = 0

CPU time = 0 ms
```

Elapsed time varied between executions and was not used as the primary decision metric because the dataset and query were very small.

---

## 9. Key Lessons

### 1. Scan is not automatically bad

A Scan can be a reasonable choice, especially for a small table.

### 2. Seek is not automatically better

A Seek can introduce additional operations such as Key Lookup.

### 3. Estimated Rows and Actual Rows must be compared

In this lab:

```text
Estimated Rows = 10
Actual Rows    = 10
```

Cardinality estimation was accurate.

### 4. Rows Read and Logical Reads are different

```text
Rows Read
→ rows processed by the operator

Logical Reads
→ data pages read from the buffer cache
```

Therefore:

```text
1010 Rows Read
```

does not mean:

```text
1010 Logical Reads
```

### 5. Key Lookup can increase I/O

The simple nonclustered index reduced Rows Read but introduced a Key Lookup:

```text
Orders Logical Reads = 22
```

### 6. Covering Index can eliminate Key Lookup

The covering index provided all required `Orders` columns and reduced:

```text
Orders Logical Reads = 2
```

### 7. Performance tuning requires measurement

The decision was based on:

- Execution Plan
- Actual Rows
- Actual Rows Read
- Logical Reads
- Key Lookup behavior
- CPU Time
- Overall execution behavior

not only on whether the operator was `Scan` or `Seek`.

### 8. Optimizer should not be overridden blindly

The Index Hint was used only for experimentation.

The final solution allowed SQL Server to choose the covering index automatically.

### 9. Index design must consider the workload

An index that improves one query may introduce:

- Storage overhead
- INSERT overhead
- UPDATE overhead
- DELETE overhead
- Maintenance cost

Therefore, index tuning should consider the broader workload rather than a single query.

---

## Conclusion

Day 32 demonstrated that effective index tuning is not simply about replacing a Scan with a Seek.

The final improvement came from designing a covering index that matched the query requirements.

Initial:

```text
Clustered Index Scan
        ↓
1010 rows read
        ↓
10 rows returned
        ↓
7 logical reads
```

Final:

```text
Covering Index
        ↓
Index Seek
        ↓
10 rows read
        ↓
10 rows returned
        ↓
2 logical reads
        ↓
No Key Lookup
```

The main lesson is:

> The goal of performance tuning is not to force SQL Server to use a Seek. The goal is to provide an appropriate design and verify the resulting behavior with real measurements.