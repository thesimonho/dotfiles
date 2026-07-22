# Cluster adapter

This directory translates observed Kubernetes state into domain objects. The JSON snapshot is a development adapter; production reads use the Kubernetes API through the same domain boundary.

GitOps readiness is part of workload health even when all currently deployed replicas are ready. This allows HomeOps to surface a healthy-but-stale deployment as degraded.
