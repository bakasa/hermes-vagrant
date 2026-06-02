# QA Agent Skill

## Purpose

This skill defines how the QA Agent reviews pull requests, evaluates quality gates, and produces verdicts. It is the operational playbook for every review.

---

## Workflow

### 1. Receive PR Notification

Trigger: webhook from GitHub/GitLab, or cron job detects new/updated PR.

Collect:
- PR number, title, author
- Source and target branches
- Diff content
- CI status (if already running)

### 2. Preflight Checks

Before deep review, run quick preflight:
- [ ] PR size ≤ 500 lines changed? If larger, flag for the author to split.
- [ ] PR description exists and explains the *why*?
- [ ] No obvious `.env`, `*.pem`, `*.key` in the diff?

If preflight fails → request changes before proceeding with full review.

### 3. Run Automated Checks

```
pytest --tb=short -q                    # Unit tests
pytest integration/ --tb=short -q       # Integration tests
bandit -r src/ --severity-level medium   # Security lint
ruff check src/                          # Code quality
mypy src/ --ignore-missing-imports       # Type checking
```

Collect all results. Any failure = automatic NO-SHIP (with the specific fix).

### 4. Quality Gate Review

Evaluate against each gate below. For each gate, record: **PASS**, **WARN**, or **FAIL** with specific evidence.

### 5. Compose Verdict

Use the structured verdict format from SOUL.md. Post as a PR comment.

---

## Quality Gates

### Gate 1: Tests

| Check | Severity if Failed |
|-------|-------------------|
| All existing tests pass | CRITICAL — NO-SHIP |
| New code has test coverage (≥80% for new lines) | HIGH — NO-SHIP |
| Edge cases are tested (empty input, max values, error paths) | MEDIUM — WARN |
| Tests are readable and not brittle | LOW — Note |

**How to evaluate:**
1. Run the test suite. If anything fails → CRITICAL.
2. Check coverage diff (e.g., `diff-cover`). If new lines are untested → HIGH.
3. Read the new tests. Do they cover boundary conditions?

### Gate 2: Code Quality

| Check | Severity if Failed |
|-------|-------------------|
| Functions are ≤ 30 lines | MEDIUM — WARN |
| Cyclomatic complexity ≤ 10 per function | MEDIUM — WARN |
| No deeply nested callbacks (>4 levels) | MEDIUM — WARN |
| Public functions have docstrings | LOW — Note |
| Type hints on public APIs | LOW — Note |
| No dead code or commented-out blocks | MEDIUM — WARN |

**How to evaluate:**
1. Quick scan of each changed file. Note specific violations with line numbers.
2. These are WARNs unless severe (e.g., 200-line function with complexity 30 → HIGH).

### Gate 3: Security

| Check | Severity if Failed |
|-------|-------------------|
| No hardcoded secrets, API keys, tokens | CRITICAL — NO-SHIP |
| All user inputs are validated/sanitized | CRITICAL — NO-SHIP |
| No SQL injection (use parameterized queries) | CRITICAL — NO-SHIP |
| No path traversal (validate file paths) | CRITICAL — NO-SHIP |
| No XSS vectors in rendered output | CRITICAL — NO-SHIP |
| Authentication/authorization checks present | CRITICAL — NO-SHIP |
| Error messages don't leak internals | HIGH — NO-SHIP |
| Dependencies have no known CVEs | HIGH — NO-SHIP |
| Crypto uses standard libraries (not custom) | CRITICAL — NO-SHIP |

**How to evaluate:**
1. Run `bandit` and `pip-audit` / `npm audit`.
2. Manual scan of the diff for the patterns above.
3. Any CRITICAL security finding = immediate NO-SHIP regardless of other gates.

### Gate 4: Functional Correctness

| Check | Severity if Failed |
|-------|-------------------|
| Change does what PR description claims | HIGH — NO-SHIP |
| Edge cases are handled (null, empty, overflow) | HIGH — NO-SHIP |
| No race conditions in concurrent code | HIGH — NO-SHIP |
| API contracts are maintained (no breaking changes) | HIGH — NO-SHIP |
| Database migrations are reversible | HIGH — NO-SHIP |
| Error paths return meaningful messages | MEDIUM — WARN |
| Logging is appropriate (not too much, not too little) | LOW — Note |

**How to evaluate:**
1. Read the PR description first. Then verify the diff actually implements it.
2. Trace the happy path and at least one error path through the code.
3. For API changes, check that responses match the documented schema.
4. For DB changes, verify migrations have downgrade paths.

---

## Verdict Logic

```
IF any CRITICAL finding:
    → VERDICT = NO-SHIP
    → List all critical findings with fixes

ELIF any HIGH finding:
    → VERDICT = NO-SHIP
    → List all high findings with fixes

ELIF only MEDIUM and LOW findings:
    → VERDICT = SHIP with Notes
    → List medium/low suggestions (non-blocking)

ELSE:
    → VERDICT = SHIP
    → Optional: kudos / follow-up suggestions
```

**Override:** If the PR is docs-only, config-only (with passing tests), or a trivial fix (typo, comment, log message), you may fast-track to SHIP with a one-line acknowledgment.

---

## Feedback Format Rules

1. **Every issue gets a fix suggestion.** "This is wrong" without "do this instead" is unacceptable.
2. **Use exact file paths and line numbers.** Never say "somewhere in the auth module."
3. **Severity labels are mandatory.** Use CRITICAL · HIGH · MEDIUM · LOW.
4. **Separate blocking from non-blocking.** Clearly mark which findings must be resolved.
5. **End with a summary.** One paragraph: what was good, what needs work, what the verdict is.

### Example Feedback

```
## VERDICT: NO-SHIP ❌

### Summary
Solid refactor of the auth module, but there's a hardcoded API key and untested error handling
in the new token refresh flow. Fix these two issues and this is good to go.

### Findings

| # | Severity | File | Line | Issue | Fix |
|---|----------|------|------|-------|-----|
| 1 | CRITICAL | src/auth/tokens.py | 23 | Hardcoded API key `"ak_live_..."` | Move to environment variable using `os.environ.get()` or a secrets manager |
| 2 | HIGH | src/auth/tokens.py | 67-89 | Token refresh error path not covered by tests | Add test cases for `refresh_token()` when the server returns 401 or 500 |

### Detail for Finding #1
Line 23: `API_KEY="ak_live_..."` — This key is committed in plaintext. Anyone with repo history can see it. Even if rotated later,
the old value is still in git history. Use `os.environ["API_KEY"]` and fail fast if missing.

### Test Results
- Unit tests: ❌ 45/47 passed (2 new tests missing for token refresh)
- Security scan: ❌ bandit B105 (hardcoded secret) found
- Code quality: ✅ ruff clean

### Notes
- Nice separation of concerns between token creation and refresh.
- Consider adding an integration test for the full auth flow.
```

---

## Operational Rules

- Review every PR within **5 minutes** of notification.
- Never approve a PR you haven't fully reviewed because "it looks small." Small PRs can have critical bugs.
- If you're unsure about a finding, escalate it. Better to flag and retract than to miss.
- Keep a log of all reviews for auditability.
- Update this skill when new quality gates or check patterns are discovered.
