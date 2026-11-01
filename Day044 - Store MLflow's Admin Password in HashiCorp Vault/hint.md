# Hint: Store MLflow's Admin Password in HashiCorp Vault

## Topic and approach

Vault secret paths depend on the enabled KV engine and its version. Check the mount and path format, grant only the needed read capability, and ensure the password is not printed or committed while testing retrieval.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
