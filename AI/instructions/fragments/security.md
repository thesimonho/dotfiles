# Security Guidelines

## Mandatory Security Checks

- [ ] No hardcoded secrets (API keys, passwords, tokens). Use environment variables instead.
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on endpoints
- [ ] Error messages don't leak sensitive data

## Security Response Protocol

If security issue found:

1. STOP immediately
2. Tell the user
3. Use **security-reviewer** agent
4. Fix CRITICAL issues before continuing
5. Review entire codebase for similar issues
