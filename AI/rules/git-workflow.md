# Git Workflow

## Branch Workflow

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

Run type checks and linters before committing

Commit your work in small, logical chunks that are easy to review and revert if needed

### Commit Message Format

```
<type>: <description>

<optional body>
```

Use conventional commit types

## Pull Request/Merge Workflow

When merging or creating PRs:

1. Use the /verification skill first to make sure no build errors come up
1. Analyze full commit history of the branch (not just latest commit)
1. Use `git diff [base-branch]...HEAD` to see all changes
1. Draft comprehensive PR summary
