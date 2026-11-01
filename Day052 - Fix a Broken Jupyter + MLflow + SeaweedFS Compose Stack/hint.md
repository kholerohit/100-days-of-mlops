# Hint: Fix a Broken Jupyter + MLflow + SeaweedFS Compose Stack

## Topic and approach

Compose services communicate using service DNS names and container ports, not necessarily host-published ports. Check environment variables, volume paths, health checks, and startup dependencies across Jupyter, MLflow, and object storage.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
