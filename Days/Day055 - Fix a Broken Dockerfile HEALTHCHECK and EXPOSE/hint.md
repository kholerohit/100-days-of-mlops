# Hint: Fix a Broken Dockerfile HEALTHCHECK and EXPOSE

## Topic and approach

`EXPOSE` documents a container port; it does not publish it, while a health check must use a tool and endpoint present in the image. Compare the app's bind port, probe command, and runtime behavior.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
