# Coding Style

## General

Adopt a "sentence readable" approach:

- Code should read like a sentence
- Prefer descriptive names over short names
- Long names are perfectly acceptable
- Use `isX` and `hasX` naming conventions for boolean checks
- Declare more variables to avoid nested or long expressions

## File Organization

MANY SMALL FILES > FEW LARGE FILES:

- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large components
- Organize by feature/domain, not by type

## Functions

- Small (<30 lines)
- Use early returns
- No deep nesting (>4 levels)
- Proper error handling
- No mutation (immutable patterns used)

## Comments

- Write docstrings. Use existing codebase conventions, or these defaults: typescript/tsx (TSDoc), python (google docstrings), go (GoDoc)
- Write comments for complex code that is difficult to understand, not for obvious code
- Comments explain why, not what - provide enough context for someone to write tests against intended behaviour
