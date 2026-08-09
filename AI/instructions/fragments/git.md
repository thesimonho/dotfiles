# Git Workflow

## Worktree

Treat every new worktree, and every worktree moved to a different commit, as a fresh runtime boundary:

- Confirm the worktree root and shared Git directory with `git rev-parse --show-toplevel` and `git rev-parse --git-common-dir` before deriving paths.
- A service started from the canonical checkout may be reusable from every worktree. Reuse it only when the project defines it as shared; do not reset, migrate, stop, or otherwise mutate a shared service unless the current task owns that lifecycle.
- Give each worktree its own application port, cache/build output, browser session, and temporary artifacts when concurrent agents could collide. Prefer a repository command that prints the selected values over guessing defaults.

## Branch Workflow

You _cannot_ push directly to main, don't even try.

## Committing

GPG sign your commits if possible. You might need to leave sandbox to do so.

### Small, logical commits

Commit often. Frequent commits = easy bisects.

Commit in small, focused chunks — each commit should be one logical change that is easy to review and revert.

- Don't bundle unrelated changes in a single commit
- Don't commit half-finished work that breaks the build

## Pull Request/Merge

Each PR should be small, focused, and self-contained. Do NOT bundle multiple issues into a single PR. If multiple issues come up, create a branch, start a subagent on the issue, or make a note of it.

When pushing, merging or creating PRs:

1. All changes are committed
2. The branch is up to date with main (rebase if needed)
3. Use a fast-forward merge strategy if possible

When handing completed work from a worktree back to the canonical checkout:

1. Commit the complete scoped work in the worktree.
2. Fast-forward the target branch in the canonical checkout when possible.
3. Check both refs point at the intended commit.
4. Remove the clean worktree, then delete its redundant local branch.

Moving an agent task between checkouts does not move uncommitted files or Git refs by itself. Use commits as the handoff boundary.
