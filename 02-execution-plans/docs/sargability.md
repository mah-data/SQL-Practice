# SARGability and Runtime Performance

## SARGability

SARGability describes whether a predicate is written in a form that allows SQL Server to use an index efficiently.

A simple equality predicate is SARGable:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 10;
```
Applying an expression or function to the indexed column can make index usage less efficient:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID + 0 = 10;
```
For date filtering, a range predicate is generally preferable to applying a function to the column:
```sql
SELECT *
FROM dbo.Orders
WHERE OrderDate >= '2026-01-01'
  AND OrderDate < '2027-01-01';
```
Instead of :
```sql
SELECT *
FROM dbo.Orders
WHERE YEAR(OrderDate) = 2026;
```

## predicate & Seek Predicate

A predicate is a condition used to determine which rows qualify for a query.

A Seek Predicate is a predicate that SQL Server can use to navigate directly through an index.

Example:

Seek Predicate:
CustomerID = 10

A separate Predicate may be evaluated after rows have been located.

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

## Actual Rows vs Actual Rows Read

These metrics are different.

Actual Rows Read indicates how many rows the operator had to read.

Actual Rows indicates how many rows the operator returned.

A large difference can indicate that SQL Server read significantly more data than it ultimately returned.

## Operator Cost

Estimated I/O Cost and Estimated CPU Cost in an execution plan are optimizer estimates.

They are not measurements of actual runtime performance.

Runtime analysis should also consider:

Logical reads
Physical reads
CPU time
Elapsed time
Actual rows
Actual rows read
Number of executions

## Runtime Performance Measurement

Runtime performance was measured using:

SET STATISTICS IO ON;

and:

SET STATISTICS TIME ON;

STATISTICS IO provides information about I/O activity such as logical reads and physical reads.

STATISTICS TIME provides CPU time and elapsed time.

## Practical Lab and Portfolio Structure

The practical Index and SARGability experiments were performed on:

dbo.IndexLab

The Git portfolio documentation uses:

dbo.Orders

This separation keeps the repository structure consistent while preserving the practical lab work.

Practical SARGability Test

The corresponding portfolio example is:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 10;
```
A non-SARGable form can be demonstrated as:
```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID + 0 = 10;
```

## Practical Finding

The practical experiment on dbo.IndexLab demonstrated a significant difference between a SARGable predicate and a non-SARGable predicate.

SARGable Predicate
CustomerID = 10

Execution Plan:

Seek Predicate:
CustomerID = 10

Actual Rows Read:

68,297

Logical Reads:

198

Physical Reads:

0

CPU Time:

203 ms

Elapsed Time:

2,670 ms
Non-SARGable Predicate
CustomerID + 0 = 10

Execution Plan:

Predicate:
(CustomerID + 0) = 10

Actual Rows Read:

6,832,996

Logical Reads:

19,603

Physical Reads:

0

CPU Time:

5,547 ms

Elapsed Time:

3,595 ms
Comparison
Metric	SARGable	Non-SARGable
Access condition	Seek Predicate	Predicate
Actual Rows Read	68,297	6,832,996
Logical Reads	198	19,603
Physical Reads	0	0
CPU Time	203 ms	5,547 ms
Elapsed Time	2,670 ms	3,595 ms

The non-SARGable query read approximately 100 times more rows.

Logical reads increased from 198 to 19,603, which is approximately 99 times more logical I/O.

CPU time increased from 203 ms to 5,547 ms, which is approximately 27 times more CPU time.

## RAM and Buffer Pool

RAM is the computer's fast temporary memory.

SQL Server uses part of RAM as the Buffer Pool.

The Buffer Pool stores data pages and index pages so SQL Server can access them without repeatedly reading them from storage.

A simplified model is:

Storage
   ↓
RAM / Buffer Pool
   ↓
CPU
   ↓
Query Result
Logical Reads

A Logical Read means SQL Server read a data page or index page from memory.

A SQL Server page is normally 8 KB.

Logical Reads = Number of pages read

Logical Reads do not represent the number of rows.

For example:

198 × 8 KB = 1,584 KB

This is approximately 1.55 MB of logical page reads.

Physical Reads

A Physical Read occurs when SQL Server needs to read a page from storage because the required page is not already available in memory.

In this experiment:

SARGable:
Physical Reads = 0


Non-SARGable:
Physical Reads = 0

Therefore, the observed performance difference was primarily related to logical I/O and CPU work rather than physical disk reads.

## CPU

CPU is the processor that executes instructions and performs calculations.

CPU is different from RAM.

RAM = stores data temporarily
CPU = processes data

CPU Time measures the processor time used by the query.

Elapsed Time measures the wall-clock time from the beginning to the end of execution.

CPU Time and Elapsed Time do not have to be equal.

## Key Findings
Write predicates in a SARGable form whenever practical.
Avoid unnecessary functions or expressions on indexed columns.
Use range predicates for date filtering.
Keep parameter and column data types compatible.
SARGability does not guarantee an Index Seek.
Always compare Estimated Rows with Actual Rows.
Actual Rows Read can reveal unnecessary data access.
Logical Reads measure pages read from memory.
Physical Reads measure pages read from storage.
Estimated plan cost is not the same as measured runtime performance.
Runtime performance should be validated using actual execution statistics.



