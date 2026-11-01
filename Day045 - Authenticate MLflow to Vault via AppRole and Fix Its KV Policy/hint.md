# Hint: Authenticate MLflow to Vault via AppRole and Fix Its KV Policy

## Topic and approach

AppRole authentication has separate role ID and secret ID inputs, and KV v2 policies address data through a versioned API path. Verify the policy against the actual mount/path and test with the same identity MLflow uses.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
