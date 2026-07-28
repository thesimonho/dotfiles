# HomeOps codemap

HomeOps separates observed infrastructure adapters from domain decisions and the web presentation layer.

| Area | Source of truth |
| --- | --- |
| Workload health | `src/domain/workloads.ts` |
| Resource template construction | `src/templates/resource-template.ts` |
| Resource template display identity | `src/templates/render-resource.ts` |
| Kubernetes observations | `src/server/cluster/` |
| HTTP endpoints | `src/server/routes/` |
| Web dashboard | `src/web/` |
| Production desired state | `manifests/production/` |
| Generated API types | Generated from server schemas; never edit `src/generated/` directly |

Read the nearest directory README before changing an adapter or operational policy.
