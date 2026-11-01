# Hint: Fix a Broken KServe InferenceService storageUri

## Topic and approach

KServe resolves `storageUri` against a real storage resource and model path. Compare the URI with the exact PVC/object-store name and inspect predictor pod events for mount or download errors.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
