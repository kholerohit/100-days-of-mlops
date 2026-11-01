# Hint: Fix a Broken Argo DAG Dependency Chain

## Topic and approach

Argo DAG dependencies refer to task names, not template names, and the resulting graph must be acyclic. Draw the intended order, compare every dependency reference with a declared task, then inspect the submitted DAG status.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
