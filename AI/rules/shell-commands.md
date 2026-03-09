# Shell Command Hygiene

Run each shell command as a **separate, simple Bash call**. Do not chain commands with `&&`, `||`, `;`, or pipes when each part is an independently meaningful operation.

This is critical — the permissions system matches against the beginning of each Bash call. Compound commands will be blocked.

This applies to all shell commands, including `git`, `npm`, `go`, etc.

## Rules

- **One operation per Bash call:** `git add`, `git commit`, `git push`, `npm run test`, etc. — each is its own tool call
- **Do not chain:** `git add . && git commit -m "msg"` will be blocked. Use two separate calls.
- **Do not wrap:** No subshells, inline scripts, or heredocs around git commands
- **Pipelines are fine** when the pipe is integral to the command (e.g., `git log --oneline | head -20`)

## Examples

```bash
# CORRECT — separate calls
git add .
# (separate Bash call)
git commit -m "feat: add user avatar"

# WRONG — chained
git add . && git commit -m "feat: add user avatar"

# WRONG — subshell
sh -c 'git add . && git commit -m "feat: add user avatar"'
```
