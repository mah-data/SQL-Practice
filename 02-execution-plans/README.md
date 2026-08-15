# SQL Server Execution Plans

Practical SQL Server exercises focused on query performance and optimization.

## Topics

- Execution Plans
- Statistics
- Cardinality Estimation
- Plan Cache
- Parameter Sniffing
- Query Optimization

## Lab

Database: `ParameterSniffingLab`

## What I Have Learned

### Cardinality Estimation

I compared estimated rows with actual rows in an execution plan.

For `CustomerID = 10`:

Estimated rows: 2611  
Actual rows: 1

After updating statistics with `FULLSCAN`:

Estimated rows: 1  
Actual rows: 1

This demonstrated how statistics can affect cardinality estimation.

### Parameter Sniffing

A stored procedure was created to investigate parameter sniffing and plan reuse.

The investigation is in progress.

### Indexing and Covering Indexes

I investigated how indexes affect query execution plans.

For a query filtering by `CustomerID`, an index on `CustomerID` allowed SQL Server to use an Index Seek.

I then tested a covering index that included the columns required by the query.

The covering index allowed SQL Server to satisfy the query directly from the index and avoid an additional Key Lookup.

This demonstrated how a covering index can reduce additional lookups and improve query performance.



