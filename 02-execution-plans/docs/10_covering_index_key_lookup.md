# Covering Index & Key Lookup

## 1. Objective

Analyze how a Covering Index can eliminate a Key Lookup and reduce logical I/O.

The lab compares the execution plan and I/O before and after creating a Covering Index on `dbo.Orders`.

---

## 2. Initial Query

```sql
SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Amount
FROM dbo.Orders
WHERE CustomerID = 10;
```

---

## 3. Initial Execution Plan

Observed execution path:

```text
IX_Orders_CustomerID
        ↓
Index Seek
        ↓
Key Lookup
        ↓
PK_Orders
```

The existing nonclustered index was:

```text
IX_Orders_CustomerID
└── Key: CustomerID
```

The Index Seek output contained:

```text
OrderID
CustomerID
```

The query also required:

```text
OrderDate
Amount
```

Therefore, SQL Server used a Key Lookup on the clustered primary key to retrieve the remaining columns.

### Key Lookup Evidence

```text
Object:
PK__Orders__C3905BAFB41E962E

Actual Rows:
1

Estimated Rows:
1
```

The estimated and actual row counts matched, so the Lookup was not caused by a cardinality estimation problem.

---

## 4. Initial I/O

Before creating the Covering Index:

```text
Scan count: 1
Logical reads: 6
Physical reads: 0
```

---

## 5. Covering Index

A Covering Index was created:

```sql
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders (CustomerID)
INCLUDE (OrderDate, Amount);
```

The index structure was verified as:

```text
IX_Orders_CustomerID_Covering
├── Key
│   └── CustomerID
│
└── Included Columns
    ├── OrderDate
    └── Amount
```

`OrderID` was not added to the `INCLUDE` list because it is the clustered key.

---

## 6. Execution Plan After Tuning

After creating the Covering Index, the Key Lookup disappeared.

The execution path became:

```text
IX_Orders_CustomerID_Covering
        ↓
Index Seek
        ↓
Result
```

Observed:

```text
Key Lookup: Not Present
```

The index now contains all nonclustered-index data required by the query.

---

## 7. I/O After Tuning

After creating the Covering Index:

```text
Scan count: 1
Logical reads: 3
Physical reads: 0
```

Comparison:

| Metric         | Before | After |
| -------------- | -----: | ----: |
| Key Lookup     |    Yes |    No |
| Logical Reads  |      6 |     3 |
| Physical Reads |      0 |     0 |

Logical reads were reduced from `6` to `3`.

---

## 8. Key Finding

A nonclustered Index Seek does not necessarily mean that the query is fully satisfied by the index.

If required columns are missing, SQL Server may perform a Key Lookup to retrieve the remaining data from the clustered index.

A Covering Index can provide the required columns directly and eliminate the Key Lookup.

The optimization path demonstrated in this lab was:

```text
Nonclustered Index
        ↓
Index Seek
        ↓
Key Lookup
        ↓
Additional I/O
```

After adding the required included columns:

```text
Covering Index
        ↓
Index Seek
        ↓
No Key Lookup
        ↓
Lower Logical I/O
```

---

## 9. Conclusion

Key Lookup is not inherently a problem.

For a very small number of rows, its cost may be acceptable.

However, when a query performs many lookups, the additional I/O can become expensive.

A Covering Index can reduce this cost by storing the additional columns required by the query.

Therefore:

> Index Seek does not always mean the query is fully covered.

> A Covering Index can eliminate Key Lookup and reduce I/O.
