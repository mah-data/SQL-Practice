# SARGability and Execution Plan Analysis

## SARGability

SARGability describes whether a predicate is written in a form that allows SQL Server to use an index efficiently.

A simple equality predicate is SARGable:

---sql
WHERE CustomerID = 10
---
Applying an expression or function to the indexed column can make index usage less efficient:
---sql
WHERE CustomerID + 0 = 10
WHERE ISNULL(CustomerID, 0) = 10
---
For date filtering, a range predicate is generally preferable to applying a function to the column:
---sql
WHERE OrderDate >= '2026-01-01'
  AND OrderDate < '2027-01-01'
---
instead of:
---sql
WHERE YEAR(OrderDate) = 2026
Predicate vs Seek Predicate
---
A predicate is a condition used to determine which rows qualify for the query.

A Seek Predicate is a predicate that SQL Server can use to navigate directly through an index.

For example:

Seek Predicate:
CustomerID = 10

This means SQL Server can use the index key to locate the relevant range.

A predicate may also be evaluated after rows have been located.

SARGable Does Not Mean Index Seek

A SARGable predicate does not guarantee an Index Seek.

The optimizer also considers:

Cardinality
Statistics
Selectivity
Data distribution
Estimated cost

Therefore, a SARGable query may still use an Index Scan.

## Estimated Rows vs Actual Rows

Estimated rows are produced by the optimizer during plan compilation.

Actual rows are observed during query execution.

A large difference between them can indicate issues involving:

Statistics
Cardinality estimation
Data distribution
Parameter sensitivity
Actual Rows vs Actual Rows Read

These metrics are different.

Actual Rows Read indicates how many rows the operator had to read.

Actual Rows indicates how many rows were returned by the operator.

A large difference can indicate that SQL Server read significantly more data than it ultimately returned.

## Actual Number of Executions

An operator can be executed many times.

For example:

Actual Number of Executions = 10000

Even a relatively inexpensive operator can become significant when executed thousands or millions of times.

## Operator Cost

Estimated I/O and CPU costs in an execution plan are optimizer estimates, not measurements of actual runtime performance.

## Runtime analysis should also consider:

Logical reads
CPU time
Elapsed time
Actual rows
Actual rows read
Number of executions
Key Findings
Write predicates in a SARGable form whenever practical.
Avoid unnecessary functions or expressions on indexed columns.
Use appropriate range predicates for date filtering.
Keep parameter and column data types compatible.
SARGability does not guarantee an Index Seek.
Always compare Estimated Rows with Actual Rows.
Actual Rows Read can reveal unnecessary data access.
Operator execution count matters when evaluating performance.
Estimated plan cost is not the same as measured runtime performance.
