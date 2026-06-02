# SKILL.md — Coder Agent Skill

## Purpose

This skill defines how the Coder Agent operates: delegating coding work to Claude Code CLI, managing pull requests, running tests, and shipping code end-to-end.

---

## 1. Delegation to Claude Code CLI

### When to Delegate

- Task involves writing, refactoring, or debugging source code.
- Task requires exploring a codebase before making changes.
- Task is complex enough that a single-shot prompt won't suffice.

### How to Delegate (Headless Mode)

```bash
# Single task, non-interactive
claude -p "Task: Implement user authentication module. Acceptance: JWT-based, unit tests, no external deps beyond pyjwt. Target: src/auth/." --allowedTools "Edit,Write,Bash,Read"

# With a file-based spec
claude -p "$(cat /tmp/task-spec.md)" --allowedTools "Edit,Write,Bash,Read" --max-turns 50
```

### Delegation Rules

1. **Always pass `--allowedTools`** — restrict to `Edit,Write,Bash,Read` unless the task needs more.
2. **Set `--max-turns`** — default 100; bump to 200 for large tasks.
3. **Write the task spec to a file first** for complex tasks, then pass the file content.
4. **Capture stdout/stderr** and log it for the task record.
5. **If Claude Code fails or times out**, retry once with `--max-turns 200`. If it fails again, escalate to Main.

### Delegation Output

After Claude Code finishes:

1. Review the diff (`git diff`).
2. Run the test suite.
3. If tests pass → open a PR (see §2).
4. If tests fail → feed failures back to Claude Code: `claude -p "Fix these test failures:\n$(test_output)"`.

---

## 2. PR Workflow

### Opening a PR

```bash
# Create a branch
git checkout -b "feat/<short-description>-<ticket>"

# Claude Code makes changes (see §1)
# ...

# Commit
git add -A
git commit -m "feat(<scope>): <description>

<what changed and why>

Signed-off-by: Coder Agent <coder@hermes>"

# Push
git push -u origin "feat/<short-description>-<ticket>"

# Open PR via GitHub CLI
gh pr create \
  --title "feat(<scope>): <description>" \
  --body "$(cat /tmp/pr-body.md)" \
  --base main \
  --reviewer "<reviewer>" \
  --label "coder-agent"
```

### PR Body Template

```markdown
## Summary
<!-- What was built and why -->

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Changes
<!-- High-level change list -->

## Tests
<!-- What was tested, what passed -->

## Notes
<!-- Anything for the reviewer to know -->
```

### Handling Review Comments

When review comments come in:

1. Parse each comment (file + line + feedback).
2. For each comment, delegate fix to Claude Code:

```bash
claude -p "Review comment on <file>:<line>:

> <feedback text>

Address this review comment. Change only what's needed." --allowedTools "Edit,Read,Bash"
```

3. Re-run tests after all fixes.
4. Push fixes: `git push` (regular push, never force-push).
5. Resolve the review comment in the GitHub UI or via `gh api`.

### Merging

```bash
# Squash merge when CI is green
gh pr merge --squash --delete-branch --subject "feat(<scope>): <description>"
```

### PR Rules — Non-Negotiable

- **Never force-push to main or any protected branch.**
- **Never merge without green CI.**
- **Never merge without required reviews** (if the repo enforces them).
- **Always squash-merge** to keep history clean.
- **Delete the feature branch after merge.**

---

## 3. Test Runner

### Auto-Run Policy

Tests run automatically after any code change, before a PR is opened. No exceptions.

### Detecting the Test Framework

```bash
# Priority order
if [ -f "package.json" ]; then grep -q '"test"' package.json && npm test; fi
if [ -f "Cargo.toml" ]; then cargo test; fi
if [ -f "go.mod" ]; then go test ./...; fi
if [ -f "pytest.ini" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then pytest; fi
if [ -f "Makefile" ]; then grep -q '^test' Makefile && make test; fi
```

### Test Failure Loop

```
Claude Code changes → run tests → if fail:
  → feed failures back to Claude Code (see §1)
  → max 3 retry cycles
  → if still failing → BLOCKED, escalate to Main
```

### Test Reporting

After tests pass:

```
✓ Tests passed: <N> passed, <N> skipped (<scope>)
```

After tests fail:

```
✗ Tests failed: <N> failed
  - <file>:<line> — <error message>
```

---

## 4. Build / Ship Cycle

The complete cycle for every task:

```
┌─────────────────────────────────────────────┐
│  RECEIVE TASK from Main / Research          │
│  (task brief + acceptance criteria)         │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  PLAN                                       │
│  — Understand the spec                      │
│  — Check existing codebase                  │
│  — Identify affected files                  │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  BUILD (delegate to Claude Code CLI)        │
│  — Implement changes                        │
│  — Write tests alongside code               │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  TEST                                       │
│  — Auto-detect framework                    │
│  — Run full suite                           │
│  — Retry up to 3 cycles if failing          │
└──────────────────┬──────────────────────────┘
                   │
              tests pass?
              /        \
           yes          no → BLOCKED → escalate
            │
            ▼
┌─────────────────────────────────────────────┐
│  PR                                         │
│  — Create branch, commit, push              │
│  — Open PR with full body                   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  REVIEW                                     │
│  — Handle review comments via Claude Code   │
│  — Push fixes                               │
└──────────────────┬──────────────────────────┘
                   │
              approved + CI green?
              /        \
           yes          waiting → wait
            │
            ▼
┌─────────────────────────────────────────────┐
│  SHIP                                       │
│  — Squash merge                             │
│  — Delete feature branch                    │
│  — Confirm merge, report to Main            │
└─────────────────────────────────────────────┘
```

---

## 5. Task Receiving

### From Main Agent (Task Brief)

Expected format:

```json
{
  "task_id": "string",
  "type": "feature|fix|refactor|test",
  "repo": "git@github.com:org/repo.git",
  "description": "string",
  "acceptance_criteria": ["string"],
  "research_signal_id": "string (optional)",
  "branch": "main",
  "reviewer": "username (optional)",
  "deadline": "ISO-8601 (optional)"
}
```

### From Research (Build Signal)

Expected format:

```json
{
  "signal_id": "string",
  "tech_spec": "path to spec document",
  "constraints": ["string"],
  "recommended_approach": "string",
  "risks": ["string"]
}
```

### Validation

On receipt, validate:

1. Task has a `repo` and `description`.
2. `acceptance_criteria` is non-empty.
3. Repo exists and is cloneable.
4. Branch exists in the remote.

If validation fails → reject immediately and report to sender.

---

## 6. Status Reporting

Always report status after each phase transition:

```
[RECEIVED]  task-42 — Implement rate limiter
[BUILDING]  task-42 — delegated to Claude Code
[TESTING]   task-42 — running pytest
[PR OPEN]   task-42 — https://github.com/org/repo/pull/123
[REVIEW]    task-42 — 2 comments addressed
[SHIPPED]   task-42 — merged to main
```

Or if blocked:

```
[BLOCKED]   task-42 — tests failing after 3 retry cycles — needs human review
```

---

## 7. Error Handling

| Error | Action |
|-------|--------|
| Claude Code timeout | Retry with `--max-turns 200`. If still times out → BLOCKED |
| Claude Code misinterprets task | Reformulate prompt with more context. Retry once. |
| Test failure after 3 retries | BLOCKED — escalate to Main with full failure output |
| PR review disagreement | Do NOT self-resolve. Escalate to Main for judgment call |
| CI flake | Retry CI once. If still flaky → BLOCK, flag CI issue |
| Merge conflict | Rebase on latest main, resolve, re-run tests, re-push |
