# Case Study #03 — Tracing SQL Server Plan Cache Behavior: Compilation, Reuse, Eviction, and Performance Evidence

## 1. Problem

SQL Server stores compiled execution plans in Plan Cache so that subsequent executions can reuse existing plans instead of compiling the statement again.

However, a cached plan is not guaranteed to remain available indefinitely.

This case study investigates observable Plan Cache behavior by tracking a target query across controlled executions and different cache conditions.

The investigation focuses on:

* Initial compilation and cache entry
* Cached-plan reuse
* Intervening Ad hoc activity
* Plan disappearance from Plan Cache
* Re-execution after the plan is no longer observable

## 2. Objective

The objective is to observe and document how the target statement behaves in SQL Server Plan Cache under controlled conditions.

Target statement:

```sql
SELECT *
FROM dbo.Orders
WHERE CustomerID = 1;
```

The investigation does not attempt to establish a universal Plan Cache timeout.

Instead, it documents behavior observed in the test environment.

## 3. Test Environment

| Item       | Value                           |
| ---------- | ------------------------------- |
| SQL Server | SQL Server 2022                 |
| Database   | JoinOptimizationLab             |
| Server     | CEO                             |
| Table      | dbo.Orders                      |
| Column     | CustomerID                      |
| Query Type | Ad hoc                          |
| Plan Cache | Cleared before controlled tests |

Plan Cache was cleared before the controlled experiments using:

```sql
DBCC FREEPROCCACHE;
```

## 4. Investigation Method

The investigation was divided into controlled experiments.

### Test 1 — Initial Compilation

The Plan Cache was cleared and the target statement was executed once.

Observed results:

| Metric               |        Result |
| -------------------- | ------------: |
| execution_count      |             1 |
| total_worker_time    |       2734 µs |
| total_elapsed_time   |     237822 µs |
| total_logical_reads  |             7 |
| total_logical_writes |             0 |
| usecounts            |             1 |
| objtype              |         Adhoc |
| cacheobjtype         | Compiled Plan |
| size_in_bytes        |         16384 |

The target statement was observable in both execution statistics and Plan Cache metadata.

**Evidence:** `evidence/initial_compilation.txt`

### Test 2 — Plan Reuse

The Plan Cache was cleared and the target statement was executed three consecutive times.

Observed results:

| Metric               |        Result |
| -------------------- | ------------: |
| execution_count      |             3 |
| total_worker_time    |      22840 µs |
| total_elapsed_time   |     701683 µs |
| total_logical_reads  |            21 |
| total_logical_writes |             0 |
| usecounts            |             3 |
| objtype              |         Adhoc |
| cacheobjtype         | Compiled Plan |
| size_in_bytes        |         16384 |

The matching `execution_count = 3` and `usecounts = 3` provide direct evidence that the cached plan was reused across the three consecutive executions under the conditions of this test.

**Evidence:** `evidence/reuse.txt`

### Test 3 — Intervening Ad hoc Activity

The Plan Cache was cleared and the target statement was executed once.

Three additional Ad hoc statements against `dbo.Customers` were then executed.

Observed results:

| Metric        |        Result |
| ------------- | ------------: |
| usecounts     |             1 |
| objtype       |         Adhoc |
| cacheobjtype  | Compiled Plan |
| size_in_bytes |         16384 |

The target plan remained observable after the intervening statements.

Therefore, eviction was not observed during this experiment.

**Evidence:** `evidence/intervening_activity.txt`

### Test 4 — Time-Based Observation

The target statement was executed once after clearing the Plan Cache.

The Plan Cache was then inspected after different idle intervals.

| Idle Interval | Observation              |
| ------------- | ------------------------ |
| 10 seconds    | Plan remained observable |
| 20 seconds    | Plan remained observable |
| 30 seconds    | Plan remained observable |
| 40 seconds    | Plan no longer observed  |
| 50 seconds    | Plan no longer observed  |

The plan was observable during the shorter intervals and was no longer observed during the 40-second and 50-second observations.

**Evidence:** `evidence/time_based_observation.txt`

## 5. Findings

### Finding 1 — Initial execution created an observable cached plan

After the initial execution, the target statement appeared as an `Adhoc` `Compiled Plan` with:

```text
usecounts       = 1
size_in_bytes   = 16384
```

This establishes the initial observable cache state in the test environment.

### Finding 2 — Repeated execution reused the cached plan

Three consecutive executions produced:

```text
execution_count = 3
usecounts       = 3
```

The paired execution-statistics and Plan Cache observations provide evidence of cached-plan reuse.

### Finding 3 — Intervening Ad hoc activity did not immediately evict the plan

Three intervening Ad hoc statements were executed.

The target plan remained observable with:

```text
usecounts = 1
objtype   = Adhoc
```

No eviction was observed during this controlled test.

### Finding 4 — The plan was no longer observable after longer idle intervals

The target plan remained observable at 10, 20, and 30 seconds.

It was no longer observed at 40 and 50 seconds.

This is an observation of the test environment, not evidence of a fixed Plan Cache expiration timeout.

## 6. Technical Interpretation

Plan Cache behavior should not be interpreted as a simple fixed-time expiration mechanism.

The experiments demonstrate that:

1. A statement can create an observable cached plan after execution.
2. Subsequent executions can reuse that cached plan.
3. Intervening Ad hoc activity does not necessarily cause immediate eviction.
4. A plan may later become unavailable from the observable Plan Cache.
5. Re-executing the statement after the previous plan is no longer observable can result in a new cached plan.

The exact reason for a plan disappearing from Plan Cache should not be inferred from elapsed time alone.

Cache state can be affected by multiple factors, including cache pressure and plan aging.

## 7. Evidence

| Evidence File                | Purpose                           |
| ---------------------------- | --------------------------------- |
| `initial_compilation.txt`    | Initial execution and cache entry |
| `reuse.txt`                  | Repeated execution and plan reuse |
| `intervening_activity.txt`   | Intervening Ad hoc activity       |
| `time_based_observation.txt` | Time-based cache observations     |

## 8. SQL Scripts

| Script                   | Purpose                                     |
| ------------------------ | ------------------------------------------- |
| `01_setup.sql`           | Prepare and verify the test environment     |
| `02_reproduce.sql`       | Reproduce the initial observation           |
| `03_trace.sql`           | Inspect execution statistics and Plan Cache |
| `04_controlled_test.sql` | Execute controlled Plan Cache experiments   |
| `05_baseline.sql`        | Establish baseline execution metrics        |

## 9. Key Takeaways

* Plan Cache enables execution-plan reuse.
* `execution_count` and `usecounts` can provide direct evidence of repeated execution and cached-plan reuse.
* Plan Cache contents are dynamic and should not be treated as permanent storage.
* Intervening Ad hoc activity does not necessarily cause immediate eviction.
* Plan disappearance after an idle interval does not, by itself, establish a fixed timeout.
* Controlled experiments and DMV evidence are required before drawing conclusions about Plan Cache behavior.

## 10. Conclusion

This case study demonstrates how SQL Server Plan Cache behavior can be investigated using controlled execution, DMV-based observation, and repeatable evidence collection.

The key lesson is that Plan Cache should be analyzed as dynamic runtime state rather than as a permanent repository of execution plans.

The experiments provide measurable evidence for initial compilation, cached-plan reuse, continued cache residency, and subsequent disappearance of the observed plan under the tested conditions.
