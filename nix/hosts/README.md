# Hosts

## How to add a host

1. Create `hosts/<name>.nix` declaring `my.os`, `my.desktop`, `my.hasDesktop` when needed,
   `my.gpu.*`, `my.identities`, `my.apps.bundles`,
   `my.ai.bundles`, etc.
2. Add a `homeConfigurations."<name>"` entry to `flake.nix` pointing at
   the right system + the new host file.
3. If the host runs CUDA, add its compute capability under
   `hostCudaCapabilities`.
4. Run `mise run build <name>` to verify, then
   `mise run switch <name>` to activate and reconcile native packages.
