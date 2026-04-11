# Git Workflow

## Worktree

If you are starting in a new worktree, check what languages, runtimes, dependencies, etc. you need to install and get those up and running first. Some may already be available, but not all.

## Branch Workflow

You _cannot_ push directly to main, don't even try.

Always start your work in a new branch created from the currently checked out branch

Naming convention: `<type>/<description>`, where type is one of the conventional commit types:

- feat: new feature
- fix: bug fix
- refactor: refactoring
- docs: documentation
- test: adding missing tests
- chore: maintenance
- perf: performance improvement
- ci: CI related changes

## Committing

The first line of a commit message should be a description of your your changed. Then the extended commit message needs to explain _why_ you changed it along with any necessary context.

GPG sign your commits if possible.

### Conventional commits

Every commit message follows the conventional commit format:

```
<type>: <short description>
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `perf`, `ci`

Keep the subject line under 70 characters. Add a body only when the "why" isn't obvious from the subject.

### Small, logical commits

Commit in small, focused chunks — each commit should be one logical change that is easy to review and revert.

- Don't bundle unrelated changes in a single commit
- Don't commit half-finished work that breaks the build

### Never Commit

- Secrets, API keys, passwords, or tokens
- `.env` files (these belong in `.gitignore`)
- Large binary files without good reason

## Pull Request/Merge Workflow

When pushing, merging or creating PRs:

1. All changes are committed
2. The branch is up to date with main (rebase if needed)
3. Verification has passed (lint, type-check, tests, build)
4. Analyze full commit history of the branch (not just latest commit)
5. Use `git diff [base-branch]...HEAD` to see all changes
6. Use a fast-forward merge strategy if possible

Once you have merged your branch, make sure you delete the local branch
