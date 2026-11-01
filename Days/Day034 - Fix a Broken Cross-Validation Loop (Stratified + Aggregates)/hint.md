# Hint: Fix a Broken Cross-Validation Loop (Stratified + Aggregates)

## Topic and approach

Stratification preserves class proportions in each fold, but aggregate metrics should be computed from the intended fold results. Check split configuration, collect one score per fold, and make the aggregation rule explicit.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
