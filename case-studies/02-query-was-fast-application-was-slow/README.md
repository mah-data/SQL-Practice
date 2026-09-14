# SQL Server Performance Case Study #02

## The Query Was Fast. The Application Was Slow.

A SQL Server performance investigation showing how a query with an efficient execution plan and very low I/O can still appear slow to the application because of blocking.

---

## 1. Case Study Objective

The goal of this case study is to investigate a simple query that is fast when executed normally, but becomes slow when another session holds a lock on the same row.

The investigation focuses on:

- Execution Plan
- CPU time
- Elapsed time
- Logical reads
- Physical reads
- Blocking
- Lock waits
- Open transactions
- Identifying the blocking session
- Identifying the SQL responsible for the blocker

---

## 2. Environment

| Item          | Value                                      |
|---------------|--------------------------------------------|
| Database      | `JoinOptimizationLab`                      |
| Table         | `dbo.Orders`                               |
| Target row    | `OrderID = 1`                              |
| Primary Key   | `PK_Orders`                                |
| SQL Server    | SQL Server                                 |
| Client        | SQL Server Management Studio               |

---

## 3. The Query

The target query is intentionally simple:

```sql
SELECT *
FROM dbo.Orders
WHERE OrderID = 1;
```

The query searches for a single row using the primary key.

---

## 4. Baseline Performance

Before introducing blocking, the query was executed with:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM dbo.Orders
WHERE OrderID = 1;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

### Observed Results

| Metric          | Result |
|-----------------|-------:|
| CPU time        | 0 ms   |
| Elapsed time    | 35 ms  |
| Logical reads   | 2      |
| Physical reads  | 0      |
| Scan count      | 0      |
| Rows returned   | 1      |

These measurements show that the query itself requires very little work.

---

## 5. Execution Plan

The Actual Execution Plan showed:

| Property                  | Result                                             |
|---------------------------|----------------------------------------------------|
| Object                    | `[JoinOptimizationLab].[dbo].[Orders].[PK_Orders]` |
| Index                     | `PK_Orders`                                        |
| Access method             | Seek                                               |
| Estimated rows            | 1                                                  |
| Actual rows               | 1                                                  |
| Seek predicate            | `OrderID = CONVERT_IMPLICIT(bigint,[@1],0)`        |
| Columns with no statistics| `OrderID`                                          |
| Warning                   | None observed                                      |

The query uses a direct seek against the primary key and returns exactly one row.

There is no evidence of an inefficient scan or excessive I/O in the baseline execution.

### Plan Note

The seek predicate displayed an implicit conversion:

`CONVERT_IMPLICIT(bigint, [@1], 0)`

The execution plan also reported:

`Columns With No Statistics: OrderID`

Neither observation is treated as the root cause in this case study.

The observed evidence shows:

- Estimated rows = 1
- Actual rows = 1
- Logical reads = 2
- Physical reads = 0
- CPU time = 0 ms
- Elapsed time = 35 ms

The investigation therefore focuses on blocking rather than attributing the delay to the access path.

---

## 6. Reproducing the Problem

A controlled blocking scenario was created using two SQL Server sessions.

### Session 1 — Blocker

```sql
USE JoinOptimizationLab;
GO

BEGIN TRAN;

UPDATE dbo.Orders
SET Amount = Amount + 1
WHERE OrderID = 1;

-- Keep the transaction open.
-- Do not COMMIT or ROLLBACK yet.
```

The transaction was intentionally left open.

### Session 2 — Blocked Query

```sql
USE JoinOptimizationLab;
GO

SELECT *
FROM dbo.Orders
WHERE OrderID = 1;
```

The SELECT statement did not complete immediately.

It became blocked while waiting for the lock held by Session 1.

---

## 7. Blocking Investigation

The active blocking request was investigated using:

```sql
SELECT
    session_id,
    blocking_session_id,
    status,
    wait_type,
    wait_time,
    wait_resource,
    command
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
```

### Observed Blocking Evidence

| Property        | Value                                      |
|-----------------|--------------------------------------------|
| Blocked session | 63                                         |
| Blocking session| 65                                         |
| Status          | `suspended`                                |
| Wait type       | `LCK_M_S`                                  |
| Wait time       | 4452 ms                                    |
| Wait resource   | `KEY: 8:72057594045792256 (1b7fe5b8af93)`  |
| Command         | `SELECT`                                   |

The important point is that the request was not spending its time executing the query.

It was waiting for a lock.

---

## 8. Investigating the Blocker

The blocking session was investigated with `sys.dm_exec_sessions`.

### Observed Blocker

| Property               | Value                                      |
|------------------------|--------------------------------------------|
| Session ID             | 65                                         |
| Status                 | `sleeping`                                 |
| Open transaction count | 1                                          |
| Login                  | `sa`                                       |
| Program                |Microsoft SQL Server Management Studio-Query|

The session was sleeping but still had an open transaction.

This is important because a sleeping session can still have an open transaction and hold locks.

---

## 9. Investigating the Transaction

The active transaction was identified using:

```sql
SELECT
    st.session_id,
    at.transaction_id,
    at.transaction_begin_time,
    at.transaction_type,
    at.transaction_state
FROM sys.dm_tran_session_transactions AS st
JOIN sys.dm_tran_active_transactions AS at
    ON st.transaction_id = at.transaction_id
WHERE st.session_id IN
(
    SELECT DISTINCT blocking_session_id
    FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
);
```

### Observed Transaction

| Property                 | Value                     |
|--------------------------|---------------------------|
| Session ID               | 65                        |
| Transaction ID           | 246093                    |
| Transaction begin time   | 2026-09-14 23:46:20.777   |
| Transaction type         | 1                         |
| Transaction state        | 2                         |

The transaction was still active while Session 65 was sleeping.

---

## 10. Finding the SQL Responsible for the Blocker

The input buffer of the blocking session was inspected.

The SQL responsible for the blocker was:

```sql
BEGIN TRAN;

UPDATE dbo.Orders
SET Amount = Amount + 1
WHERE OrderID = 1;
```

This update modified the same row requested by the blocked SELECT.

The transaction had not yet been committed or rolled back.

---

## 11. Why the Query Appeared Slow

There were two very different execution scenarios.

### Normal Execution

| Metric          | Result               |
|-----------------|----------------------|
| CPU time        | 0 ms                 |
| Elapsed time    | 35 ms                |
| Logical reads   | 2                    |
| Physical reads  | 0                    |
| Rows returned   | 1                    |
| Access method   | Seek                 |
| Index           | `PK_Orders`          |

### Blocked Execution

| Metric           | Result                                      |
|------------------|---------------------------------------------|
| Blocked session  | 63                                          |
| Blocking session | 65                                          |
| Wait type        | `LCK_M_S`                                   |
| Observed wait    | 4452 ms                                     |
| Resource         | `KEY: 8:72057594045792256 (1b7fe5b8af93)`   |

The normal query completed in approximately 35 ms.

During the blocking test, the request spent approximately 4452 ms waiting for a lock.

These are different measurements and should not be treated as the same metric.

---

## 12. Important Measurement Distinction

The `4452 ms` value came from:

```sql
sys.dm_exec_requests.wait_time
```

It represents the observed wait time for the blocked request at the time it was inspected.

It is **not** the same as:

```text
STATISTICS TIME
Elapsed time
```

Therefore:

| Measurement                 | Value    |
|-----------------------------|---------:|
| Normal query elapsed time   | 35 ms     |
| Observed blocking wait time | 4452 ms  |

---

## 13. Resolution

The blocking transaction was rolled back in Session 65:

```sql
ROLLBACK;
```

After the rollback:

- The lock was released.
- Session 63 stopped waiting.
- The SELECT completed.

`ROLLBACK` was the appropriate resolution for this controlled laboratory test because the transaction was intentionally created for the experiment.

In a production incident, the correct action depends on the business context and the transaction involved. The blocker should be investigated before terminating a session.

---

## 14. Root Cause

The root cause in this controlled case study was an open transaction.

The sequence was:

1. Session 65 started a transaction.
2. Session 65 updated `OrderID = 1`.
3. The transaction remained open.
4. The session became idle/sleeping while the transaction was still active.
5. The lock remained held.
6. Session 63 attempted to read the same row.
7. Session 63 was suspended with `LCK_M_S`.
8. The apparent query delay was caused by blocking.

---

## 15. Performance Interpretation

The execution plan did not indicate a query tuning problem.

The baseline evidence showed:

| Metric          | Result               |
|-----------------|----------------------|
| Access method   | Clustered Index Seek |
| Estimated rows  | 1                    |
| Actual rows     | 1                    |
| Logical reads   | 2                    |
| Physical reads  | 0                    |
| CPU time        | 0 ms                 |
| Elapsed time    | 35 ms                 |

The blocking evidence showed:

| Metric            | Result                                     |
|-------------------|--------------------------------------------|
| Blocked session   | 63                                         |
| Blocking session  | 65                                         |
| Wait type         | `LCK_M_S`                                  |
| Wait time         | 4452 ms                                    |
| Open transactions | 1                                          |
| Transaction ID    | 246093                                     |

Therefore, the investigation points to **blocking as the source of the observed delay**, rather than inefficient query execution.

---

## 16. Production Lessons

### Keep Transaction Scopes Short

Transactions should contain only the work that needs to be atomic.

### Commit or Rollback Reliably

An application should not leave transactions open unintentionally.

### Do Not Assume a Sleeping Session Is Harmless

A sleeping session can still have an open transaction and hold locks.

### Investigate the Blocker

When a request is blocked, identify:

- Blocked session
- Blocking session
- Wait type
- Wait resource
- Transaction state
- SQL responsible for the blocker

### Separate Query Performance from Wait Time

A query can have an efficient execution plan and low I/O while the request still experiences a long delay because it is waiting on another resource.

---

## 17. Reproduction Scripts

The complete reproduction and investigation scripts are available in the `sql` directory:

```text
sql/
├── 01_setup.sql
├── 02_reproduce_blocking.sql
├── 03_investigate_blocking.sql
└── 04_verify_performance.sql
```

### Script 01

Verifies the database and target table.

### Script 02

Reproduces the controlled blocking scenario using two sessions.

### Script 03

Investigates the blocked request, blocker session, active transaction, and blocking SQL.

### Script 04

Captures the baseline execution plan and performance statistics and documents the observed evidence.

---

## 18. Evidence Summary

| Category                     | Evidence                                           |
|------------------------------|----------------------------------------------------|
| Query                        | `SELECT * FROM dbo.Orders WHERE OrderID = 1`       |
| Object                       | `[JoinOptimizationLab].[dbo].[Orders].[PK_Orders]` |
| Access method                | Seek                                               |
| Index                        | `PK_Orders`                                        |
| Estimated rows               | 1                                                  |
| Actual rows                  | 1                                                  |
| Logical reads                | 2                                                  |
| Physical reads               | 0                                                  |
| CPU time                     | 0 ms                                               |
| Normal elapsed time          | 35 ms                                              |
| Blocked session              | 63                                                 |
| Blocking session             | 65                                                 |
| Wait type                    | `LCK_M_S`                                          |
| Observed blocking wait time  | 4452 ms                                            |
| Open transactions on blocker | 1                                                  |
| Blocking transaction         | 246093                                             |
| Resolution in lab            | `ROLLBACK`                                         |

---

## 19. Final Conclusion

This case study demonstrates an important SQL Server performance diagnostic principle:

**A slow application request does not necessarily mean the query itself is slow.**

In this controlled experiment:

- The query used a Clustered Index Seek.
- It returned one row.
- It required only 2 logical reads.
- CPU time was 0 ms.
- Normal elapsed time was approximately 35 ms.
- The delayed request was suspended on `LCK_M_S`.
- Another session held an open transaction on the same row.
- Rolling back the transaction released the lock.

The investigation therefore separated two different problems:

**Query execution performance**

from

**Resource waiting caused by blocking.**

That distinction is essential when diagnosing SQL Server performance issues in real environments.