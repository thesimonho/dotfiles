# HomeOps

HomeOps is an internal web control plane for a simulated Kubernetes homelab. It presents observed cluster, network, DNS, certificate, storage, and backup state alongside the GitOps configuration that owns intended production changes.

Use the repository's `justfile` for supported development and diagnostic commands. Treat direct cluster mutations as operational changes: perform them only when the task explicitly authorizes them.
