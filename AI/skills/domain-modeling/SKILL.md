---
name: domain-modeling
description: Keep a project's domain terminology and domain operations consistent across conversation, documentation, and code. Use as an overlay whenever another workflow introduces, interprets, challenges, or records domain language.
---

# Domain Modeling

Apply this skill as an overlay to the active workflow. Do not replace planning, wayfinding, triage, or implementation. Keep domain terms and domain operations precise and consistent while that work proceeds.

This skill owns ubiquitous language, not architectural or implementation decisions. Record resolved terminology in the glossary. Leave decisions and implementation detail in the artifact owned by the active workflow.

## File structure

Most repos have a `docs/` directory:

```raw
/
├── docs/
│   ├── codemaps/
│   ├── plans/
│   ├── glossary.md
│   ├── README.md
│   └── ...
└── src/
```

`docs/README.md` tells you about the content and structure of the documentation. Read this first.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in the docs or the codebase, call it out immediately. "Your codebase defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Keep domain operations consistent

Treat operations such as creating, cancelling, assigning, publishing, or settling as part of the domain language. Check that an operation's name, actor, target, preconditions, and outcome mean the same thing in the conversation, glossary, plans, tickets, and code.

When two operations use the same verb for different behavior, or different verbs for the same behavior, surface the mismatch and resolve the canonical language before the active workflow proceeds.

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update glossary.md inline

When a term is resolved, update `glossary.md` right there. Don't batch these up — capture them as they happen.

`glossary.md` should be totally devoid of implementation details. Do not treat `glossary.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

If no glossary exists, follow the documentation structure described by `docs/README.md`. Ask before creating a new documentation convention.
