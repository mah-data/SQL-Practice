# Join Optimization

## Objective

Analyze SQL Server Join operators and understand how the Query Optimizer chooses between:

- Nested Loops
- Hash Match
- Merge Join

The analysis is based on actual Execution Plans from `JoinOptimizationLab`.
## 1. Nested Loops

Nested Loops processes rows from one input and searches the other input for matching rows.

### Tested Query

    SELECT
        o.OrderID,
        o.CustomerID,
        c.CustomerName
    FROM dbo.Orders AS o
    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID
    WHERE o.CustomerID = 10;

### Observed Execution Plan

- Join Operator: `Nested Loops`
- `Orders`: Clustered Index Scan
- `Customers`: Index Seek
- Actual Number of Rows: `10`
- Estimated Number of Rows: `10`
- Actual Number of Rows Read from `Orders`: `1010`

### Analysis

Nested Loops can be efficient when one input is small and the other side can be accessed efficiently, for example through an Index Seek.

## 2. Merge Join

Merge Join processes two inputs by comparing their join keys in an appropriate order.

### Tested Query

    SELECT
        o.OrderID,
        o.CustomerID,
        c.CustomerName
    FROM dbo.Orders AS o
    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID;

### Observed Execution Plan

- Join Operator: `Merge Join`
- `Orders`: Nonclustered Index Scan
- `Customers`: Clustered Index Scan
- Many-to-Many: `False`
- Actual Number of Rows: `1010`
- Estimated Number of Rows: `1010`

### Analysis

The Estimated Number of Rows matched the Actual Number of Rows.

Merge Join can be effective when the input data is available in an appropriate order for the join operation.

## 3. Hash Match

Hash Match builds a hash table from one input and uses the other input to probe that hash table for matching rows.

### Tested Query

    SELECT
        o.OrderID,
        o.CustomerID,
        c.CustomerName
    FROM dbo.Orders AS o
    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID
    OPTION (HASH JOIN);

### Observed Execution Plan

- Physical Operation: `Hash Match`
- Hash Keys Build: `Customers.CustomerID`
- Hash Keys Probe: `Orders.CustomerID`
- Actual Number of Rows: `1010`
- Estimated Number of Rows: `1010`

### Build

SQL Server builds a hash table using `Customers.CustomerID`.

### Probe

SQL Server reads `Orders.CustomerID` and probes the hash table to find matching values.

### Analysis

The Estimated Number of Rows matched the Actual Number of Rows.

## 4. Cross Join Experiment

A Cross Join was tested to observe how SQL Server handles a larger result set.

### Tested Query

    SELECT
        o.OrderID,
        o.CustomerID,
        c.CustomerName
    FROM dbo.Orders AS o
    CROSS JOIN dbo.Customers AS c;

### Observed Execution Plan

- Join Operator: `Nested Loops`
- `Orders`: Scan
- `Customers`: Scan
- Actual Number of Rows: `10100`
- Estimated Number of Rows: `10100`

### Result Calculation

Orders contains `1010` rows and Customers contains `10` rows.

`1010 × 10 = 10100`

### Analysis

The test demonstrated that a larger result set does not automatically mean SQL Server will choose Hash Match.

## 5. Estimated vs Actual Rows

Estimated Number of Rows represents the number of rows SQL Server expects an operator to process.

Actual Number of Rows represents the number of rows the operator actually processed.

### Observed Results

In the tested Join scenarios:

- Estimated Number of Rows matched Actual Number of Rows.
- No significant cardinality estimation error was observed.

Example:

    Estimated = 1010
    Actual    = 1010

### Analysis

Accurate cardinality estimation helps the Query Optimizer make better cost-based decisions.

When Estimated and Actual row counts differ significantly, the execution plan may be based on an inaccurate estimate and can lead to inefficient choices.

## 6. Join Operator Comparison

| Join Operator | Main Idea | Typical Strength |
|---|---|---|
| Nested Loops | Process rows from one input and search the other input | Small input with efficient lookup |
| Hash Match | Build a hash table and probe it using the other input | Larger unsorted inputs |
| Merge Join | Process two appropriately ordered inputs together | Ordered inputs |

### Key Point

No Join operator is always better than the others.

The Query Optimizer considers factors such as:

- Estimated row counts
- Available indexes
- Data ordering
- Selectivity
- CPU cost
- I/O cost
- Statistics
- Query shape

## 7. Performance Tuning Lesson

A Scan is not automatically bad.

A Hash Match is not automatically bad.

A Nested Loops Join is not automatically good.

The correct approach is to analyze the complete Execution Plan together with:

- Estimated vs Actual Rows
- Logical Reads
- CPU Time
- Elapsed Time
- Index usage
- Statistics
- Operator costs

### Key Principle

Performance tuning should be based on evidence rather than the name of a single operator.

The goal is not to force a specific Join operator, but to understand why the Query Optimizer selected it and determine whether the overall execution plan is efficient.

## 8. Conclusion

Day 31 demonstrated the three major SQL Server Join strategies:

- Nested Loops
- Hash Match
- Merge Join

The experiments showed how SQL Server can use different Join operators depending on the query, data volume, indexes, and estimated cost.

The main lesson is that no Join operator is inherently good or bad.

Performance tuning requires analyzing the complete execution plan and validating the optimizer's decisions using actual execution metrics.