# Selectivity & Index Usefulness

## 1. Objective

Analyze how data selectivity and data distribution affect SQL Server
index usefulness and access path selection.

The lab compares `Index Seek` and `Index Scan` using different
`CustomerID` values in `dbo.Orders`.

---

## 2. Data Distribution

The `Orders` table contains:

- Total rows: 6,817,330
- Distinct CustomerID values: 10

The data is highly skewed:

| CustomerID |    Rows   |
|------------|----------:|
|      1     | 6,817,321 |
|      2     |     1     |
|      3     |     1     |
|      4     |     1     |
|      5     |     1     |
|      6     |     1     |
|      7     |     1     |
|      8     |     1     |
|      9     |     1     |
|      10    |     1     |

This creates a significant difference in selectivity between
`CustomerID = 1` and `CustomerID = 10`.

---

## 3. Selectivity

For `CustomerID = 10`:

- Rows returned: 1
- Total rows: 6,817,330
- Selectivity: approximately 0.0000147%

For `CustomerID = 1`:

- Rows returned: 6,817,321
- Total rows: 6,817,330
- Selectivity: approximately 99.9999%

Therefore, `CustomerID = 10` is highly selective, while
`CustomerID = 1` has extremely low selectivity.

---

## 4. Execution Plan Evidence

### CustomerID = 10

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 10;
```
Observed:

- Access Path: Index Seek
- Actual Rows: 1
- Estimated Rows: 1
- CustomerID = 1

```sql

SELECT *
FROM dbo.Orders
WHERE CustomerID = 1;
``` 
Observed:

- Access Path: Index Scan
- Actual Rows: 6,817,321
- Estimated Rows: 6,817,320

The cardinality estimation was highly accurate for both predicates.

## 5. I/O Evidence
- CustomerID = 10
- Logical Reads: 6
- Physical Reads: 6
- Scan Count: 1
- CustomerID = 1
- Logical Reads: 24,527
- Physical Reads: 780
- Read-Ahead Reads: 24,532
- Scan Count: 1

The highly selective predicate required significantly less logical I/O.

## 6. Statistics Evidence

Statistics:

- IX_Orders_CustomerID

Observed:

- Rows: 6,817,330
- Rows Sampled: 6,817,330
- Steps: 6
- Modification Counter: 0
- Last Updated: 2026-08-10 09:52:02

The histogram reflects the highly skewed distribution of
CustomerID.

## 7. Key Finding

Index usefulness is not determined only by the existence of an index.

SQL Server considers estimated row counts, data distribution,
selectivity, and estimated cost when choosing an access path.

In this lab:

   High Selectivity
       ↓
   Few Rows
       ↓
   Index Seek
       ↓
   Low Logical I/O

while:

   Low Selectivity
       ↓
   Many Rows
       ↓
   Index Scan
       ↓
   Higher Logical I/O

## 8. Conclusion

- The lab demonstrates that the same index can result in different
access paths depending on the selectivity of the predicate.

- Accurate statistics allow the optimizer to estimate cardinality
correctly and choose an appropriate access path.

Therefore:

   - Index existence does not guarantee Index Seek.

   - Index usefulness depends on how selective the predicate is and
   - how many rows the query needs to process.


