# Hint: Enforce a Data-Quality Checkpoint as a Blocking CI Gate

## Topic and approach

A quality check only blocks CI if its process exit status reaches the workflow. Verify the checkpoint command fails on invalid data and that the job does not swallow or ignore that failure.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
