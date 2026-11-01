# Hint: Fix MLflow's Remote Artifact-Store Wiring (PostgreSQL + SeaweedFS)

## Topic and approach

The tracking database stores run metadata; the artifact store holds files, and the server must be able to reach both. Check endpoint URLs and credentials from the server's environment, then test an artifact upload and download.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
