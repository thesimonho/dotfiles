# HomeOps agent instructions

- Start with `docs/codemaps/README.md` and the nearest README for the area you change.
- Use the `justfile` recipes for builds, tests, and diagnostics.
- Treat `src/generated/**` as generated output; change its source or generator instead.
- Production configuration is GitOps-managed under `manifests/production/`. Do not mutate production cluster state directly unless the task explicitly authorizes it.
- Never expose secret values in commands, logs, patches, or responses.
- Preserve pre-existing working-tree changes and keep the operational blast radius no larger than the task requires.
