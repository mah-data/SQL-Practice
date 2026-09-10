# SQL Server Performance Case Study #01

## When an Index Seek Isn't Enough

> **An index existing does not guarantee good performance. Selectivity matters.**

---

## Executive Summary

This case study investigates how **data distribution and predicate selectivity** can dramatically affect SQL Server query performance, even when an appropriate index exists.

A controlled workload was created using the `dbo.Orders` table with approximately **6.8 million rows** and a highly skewed `CustomerID` distribution.

The same indexed column produced significantly different execution behavior depending on the value being searched.

### Key Result

| Predicate         | Access Path | Logical Reads |
| ----------------- | ----------- | ------------: |
| `CustomerID = 10` | Index Seek  |         **6** |
| `CustomerID = 1`  | Index Scan  |    **24,527** |

The difference was caused primarily by **data skew and selectivity**.

---

# 1. The Problem

A common assumption in SQL Server performance tuning is:

> **Index Seek = Good Performance**

This case study demonstrates why that assumption is incomplete.

The workload uses the same indexed column:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 10;
```

and:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 1;
```

However, different values can have radically different selectivity.

---

# 2. Test Environment

**Database:** `JoinOptimizationLab`

**Table:** `dbo.Orders`

**Rows:** `6,817,330`

**Indexed Column:** `CustomerID`

**Index:** `IX_Orders_CustomerID`

---

# 3. Data Distribution

The test dataset was intentionally created with a highly skewed distribution.

| CustomerID |          Rows |
| ---------: | ------------: |
|          1 |     6,817,321 |
|          2 |             1 |
|          3 |             1 |
|          4 |             1 |
|          5 |             1 |
|          6 |             1 |
|          7 |             1 |
|          8 |             1 |
|          9 |             1 |
|         10 |             1 |
|  **Total** | **6,817,330** |

This distribution is the foundation of the performance difference.

`CustomerID = 1` matches almost the entire table, while `CustomerID = 10` matches only one row.

---

# 4. Baseline Test

## Test A — Highly Selective Predicate

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 10;
```

### Result

```text
Access Path: Index Seek
Logical Reads: 6
```

Only a very small number of rows qualify.

---

## Test B — Highly Non-Selective Predicate

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 1;
```

### Result

```text
Access Path: Index Scan
Logical Reads: 24,527
Physical Reads: 780
Read-Ahead Reads: 24,532
```

`CustomerID = 1` matches almost the entire table.

The amount of data that must be processed is therefore dramatically larger.

---

# 5. Root Cause

## Data Skew + Low Selectivity

The problem was not simply the absence of an index.

The index existed.

The critical difference was **how many rows the predicate matched**.

```text
CustomerID = 10
        ↓
Highly selective
        ↓
Very few matching rows
        ↓
Index Seek
        ↓
6 logical reads
```

Compared with:

```text
CustomerID = 1
        ↓
Extremely low selectivity
        ↓
Millions of matching rows
        ↓
Large amount of data processing
        ↓
24,527 logical reads
```

The access path chosen by SQL Server is influenced by the expected cost of retrieving the qualifying rows.

---

# 6. Statistics Investigation

Statistics were inspected to determine whether stale statistics could explain the observed behavior.

Relevant information included:

* Row count
* Modification count
* Statistics update time
* Distribution information

At the time of investigation:

```text
Rows:               6,817,330
Modification Count: 0
Last Updated:       2026-08-10 09:52:02.860
```

The evidence did not point to stale statistics as the primary cause.

The observed behavior was consistent with the underlying **data distribution and predicate selectivity**.

---

# 7. Performance Evidence

The investigation used multiple sources of evidence rather than relying on the execution-plan operator alone.

## Execution Plan

The two predicates produced different access strategies:

```text
CustomerID = 10
→ Index Seek

CustomerID = 1
→ Index Scan
```

## STATISTICS IO

The I/O difference was substantial:

```text
CustomerID = 10

Logical Reads: 6
```

versus:

```text
CustomerID = 1

Logical Reads: 24,527
Physical Reads: 780
Read-Ahead Reads: 24,532
```

## STATISTICS TIME

CPU time and elapsed time were also captured during the investigation to evaluate the runtime impact.

The key point is that the execution plan was evaluated together with actual runtime evidence.

---

# 8. Why an Index Seek Isn't Enough

An execution-plan operator should never be evaluated in isolation.

An Index Seek can still result in substantial work when the predicate is not selective.

The correct performance question is not:

> "Does the query use an Index Seek?"

It is:

> **"Is the chosen access path efficient for the number of rows this workload actually needs to process?"**

This distinction is important in real-world performance tuning because an index can be technically valid while providing little benefit for a highly non-selective predicate.

---

# 9. Performance Tuning Method

This investigation followed an evidence-driven workflow:

```text
Problem
   ↓
Measure
   ↓
Execution Plan
   ↓
I/O / CPU / Elapsed Time
   ↓
Cardinality
   ↓
Selectivity & Data Distribution
   ↓
Root Cause
   ↓
Optimization Decision
   ↓
Measure Again
```

This approach avoids blindly adding indexes based only on an execution-plan operator.

The objective is not simply to obtain an **Index Seek**.

The objective is to reduce the actual work SQL Server must perform for the workload.

---

# 10. Key Lessons

## 1. Index presence does not guarantee performance

An index can exist and still be inefficient for a particular workload.

## 2. Selectivity matters

A predicate returning one row behaves very differently from one returning millions of rows.

## 3. Data distribution matters

Highly skewed data can fundamentally change the cost of an access path.

## 4. Execution plans need runtime evidence

Execution plans should be analyzed together with:

* Logical reads
* Physical reads
* CPU time
* Elapsed time
* Cardinality
* Statistics

## 5. Performance tuning should be evidence-driven

The goal is not to make a plan look good.

The goal is to reduce the actual work SQL Server must perform.

---

# 11. Reproduction

The SQL scripts used to reproduce this investigation are located in:

```text
sql/
```

Run them in the following order:

```text
01_setup_database.sql
02_create_table.sql
03_load_data.sql
04_create_indexes.sql
05_baseline_tests.sql
06_statistics.sql
```

The scripts create the test environment, generate the skewed dataset, create the index, execute the workload, and collect performance evidence.

> **Note:** The existing `JoinOptimizationLab` database used during the original investigation contains the same workload and evidence documented in this case study.

---

# 12. Portfolio Context

This case study is part of an ongoing **SQL Server Performance / DBA portfolio**.

Related areas investigated in the portfolio include:

* Execution Plans
* Cardinality Estimation
* Parameter Sniffing
* SARGability
* Covering Indexes
* Composite Indexes
* Join Optimization
* Index Access Path Optimization
* Selectivity and Index Usefulness

The purpose of these case studies is to demonstrate practical, evidence-driven SQL Server performance investigation rather than only theoretical knowledge.

---

# 13. Final Takeaway

> **An index is a tool, not a performance guarantee.**

The effectiveness of an index depends on the relationship between:

**Query + Data Distribution + Selectivity + Cardinality + Access Path + Runtime Evidence**

Understanding that relationship is essential for reliable SQL Server performance tuning.
