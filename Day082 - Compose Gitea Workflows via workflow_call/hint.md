# Hint: Compose Gitea Workflows via workflow_call

## Topic and approach

A reusable workflow must declare `workflow_call` inputs/secrets and be invoked using the correct workflow path and ref. Trace one input from caller to callee and check that the called job is visible in the run.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
