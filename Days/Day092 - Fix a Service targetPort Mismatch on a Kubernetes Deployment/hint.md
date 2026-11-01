# Hint: Fix a Service targetPort Mismatch on a Kubernetes Deployment

## Topic and approach

A Service selects pods by labels and forwards its `port` to `targetPort`. Compare the target with the container's listening port and inspect the generated Endpoints before testing traffic.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
