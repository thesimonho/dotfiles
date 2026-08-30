# Git Workflow

## Worktree

Treat every new worktree, and every worktree moved to a different commit, as a fresh runtime boundary:

- Confirm the worktree root and shared Git directory with `git rev-parse --show-toplevel` and `git rev-parse --git-common-dir` before deriving paths.
- You'll need to install the project dependencies in the worktree if you intend to run it.
  - A service started from the canonical checkout may be reusable from every worktree. Reuse it only when the project defines it as shared; do not reset, migrate, stop, or otherwise mutate a shared service unless the current task owns that lifecycle.
- Give each worktree its own application port, cache/build output, browser session, and temporary artifacts when concurrent agents could collide. Prefer a repository command that prints the selected values over guessing defaults.

## Branch Workflow

You _cannot_ push directly to main, don't even try.

## Committing

Commit often. Frequent commits = easy bisects.

GPG sign your commits if possible. You might need to leave sandbox to do so.

## PR/Merge

Use the `verify` skill just before submitting a PR or merging into another branch.

## GitHub

When working with GitHub, use `gh` cli directly instead of agent connectors.
