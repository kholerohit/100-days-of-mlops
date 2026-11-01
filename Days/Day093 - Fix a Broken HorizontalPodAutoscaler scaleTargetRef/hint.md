# Hint: Fix a Broken HorizontalPodAutoscaler scaleTargetRef

## Topic and approach

An HPA's scale target is an API object reference, not a free-form display name. Check API version, kind, and deployment name, then verify resource metrics are available before judging whether scaling works.

## Work independently

Use this as a starting point, then confirm the task requirements and validate the resulting state before consulting the solution.
