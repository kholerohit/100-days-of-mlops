# Hint: Async Predictions with a Redis-Backed Worker

## Topic and approach

An asynchronous prediction API needs a durable handoff between request acceptance and worker execution. Trace the job ID through Redis enqueue, worker consumption, status updates, and result retrieval, including failure states.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
