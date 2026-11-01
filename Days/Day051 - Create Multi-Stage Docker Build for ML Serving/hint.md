# Hint: Create Multi-Stage Docker Build for ML Serving

## Topic and approach

A multi-stage image should keep compilers and build-only dependencies out of the final runtime layer. Trace which artifacts must cross stages and confirm the final image can start the service with only its runtime dependencies.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
