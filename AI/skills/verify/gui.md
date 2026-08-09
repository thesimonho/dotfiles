# GUI Verification

## Browser Use

You have access to the agent-browser skill and CLI (it should already be installed; flag if it isn't). Use this when you need access to dev tools for a web app, or when you need to interact with a page (get content, fill fields, click elements, screenshot, etc).

Quick start:

```bash
agent-browser open example.com
agent-browser snapshot                    # Get accessibility tree with refs
agent-browser click @e2                   # Click by ref from snapshot
agent-browser fill @e3 "test@example.com" # Fill by ref
agent-browser get text @e1                # Get text by ref
agent-browser screenshot page.png
agent-browser close
```

Run `agent-browser skills get core --full` for a full run guide and examples, if needed.

For local application verification:

- Start the app with the repository's agent/development command and use the URL it prints. Do not assume port 3000 or reuse a server whose owning checkout is unknown.
- Confirm the page is served by the intended worktree before drawing conclusions; concurrent checkouts may expose visually identical apps on different ports.
- Use a worktree-scoped browser session. Test a semantic user flow, including authentication when relevant, and inspect console errors and failed network requests.
- Exercise at least one meaningful read and write when the change depends on a backend, then restore test data unless the fixture is disposable.
- Stop only the frontend and browser sessions owned by the current worktree. Leave documented shared services running.
- Report the checkout, URL, route, user state, interaction, console/network result, and any screenshot or recording path. Do not report a canonical-checkout test as worktree evidence.

### Runtime verification budget

Verification should prove the changed behaviour with the fewest meaningful
interactions. This is true for web apps, but also desktop and mobile apps via their own tooling.

- Use one planned semantic user flow.
- Take screenshots only before and after a meaningful state change, not after
  every click or input attempt.
- Retry the same GUI automation mechanism at most twice.
- After two failed attempts, switch to a materially different verification
  method or report that the runtime interaction could not be verified.
- Prefer deterministic state, storage, API, accessibility-tree, or test evidence
  over coordinate-based GUI automation when either can prove the same claim.
- Do not verify unrelated platforms unless the change affects shared
  cross-platform behaviour or the ticket explicitly requires them.
