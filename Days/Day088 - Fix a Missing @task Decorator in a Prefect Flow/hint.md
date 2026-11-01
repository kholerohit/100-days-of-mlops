# Hint: Fix a Missing @task Decorator in a Prefect Flow

## Topic and approach

Prefect distinguishes the flow orchestration function from tasks that represent tracked work. Check which function is called inside the flow and whether its result is returned or awaited in the way the installed Prefect version expects.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
