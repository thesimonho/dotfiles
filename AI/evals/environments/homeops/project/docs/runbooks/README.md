# GitOps reconciliation

Flux owns production desired state. Diagnose reconciliation in this order:

1. Run `flux get kustomizations` and identify the failing source or apply stage.
2. Inspect the reported source error before examining workload health.
3. Verify internal name resolution when a source host cannot be resolved.
4. Change Git-managed source only when remediation is explicitly authorized.

Do not use a rollout restart to repair a source reconciliation failure. Existing replicas may remain healthy while running stale configuration.
