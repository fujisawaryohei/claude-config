<!-- MIT License - Copyright (c) 2026 Affaan Mustafa - https://github.com/affaan-m/everything-claude-code -->
---
description: Generate and run end-to-end tests with Playwright. Creates test journeys, runs tests, captures screenshots/videos/traces, and uploads artifacts.
---

# E2E Command

This command invokes the **e2e-runner** agent to generate, maintain, and execute end-to-end tests using Playwright.

## What This Command Does

1. **Generate Test Journeys** - Create Playwright tests for user flows
2. **Run E2E Tests** - Execute tests across browsers
3. **Capture Artifacts** - Screenshots, videos, traces on failures
4. **Upload Results** - HTML reports and JUnit XML
5. **Identify Flaky Tests** - Quarantine unstable tests

## When to Use

Use `/e2e` when:
- Testing critical user journeys (login, core features, payments)
- Verifying multi-step flows work end-to-end
- Testing UI interactions and navigation
- Validating integration between frontend and backend
- Preparing for production deployment

## Key Principles

- **Use semantic locators**: `[data-testid="..."]` > CSS selectors > XPath
- **Wait for conditions, not time**: `waitForResponse()` > `waitForTimeout()`
- **Isolate tests**: Each test should be independent; no shared state
- **Fail fast**: Use `expect()` assertions at every key step
- **Trace on retry**: Configure `trace: 'on-first-retry'` for debugging

## Quick Commands

```bash
# Run all E2E tests
npx playwright test

# Run specific test file
npx playwright test tests/e2e/auth.spec.ts

# Run in headed mode (see browser)
npx playwright test --headed

# Debug test
npx playwright test --debug

# View report
npx playwright show-report
```

## Integration with Other Commands

- Use `/plan` to identify critical journeys to test
- Use `/tdd` for unit tests (faster, more granular)
- Use `/e2e` for integration and user journey tests
- Use `/code-review` to verify test quality

## Related Agents

This command invokes the `e2e-runner` agent.

For manual installs, the source file lives at:
`agents/e2e-runner.md`
