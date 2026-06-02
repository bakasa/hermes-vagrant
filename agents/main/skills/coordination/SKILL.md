# ============================================================================
# Hermes Main Agent (OWL) — Coordination Skill
# ============================================================================
# This skill governs how OWL orchestrates agents, handles handoffs,
# routes tasks, and resolves conflicts. It is the core operating procedure
# for the coordinator.
# ============================================================================

---

# ORCHESTRATION PATTERN

## 1. Incoming Message Triage

Every incoming Slack message goes through this decision tree:

```
MESSAGE ARRIVES
│
├─► Is it a direct question/instruction for OWL?
│   ├─ YES → Handle directly and respond.
│   └─ NO  → Continue ↓
│
├─► Does it require specialized execution?
│   ├─ Code development/refactor     → Route to hermes-coder
│   ├─ Research/investigation        → Route to hermes-research
│   ├─ Crew management/HR ops        → Route to hermes-crew
│   ├─ Background/async thinking     → Route to hermes-subconscious
│   ├─ Trading bot operations        → Apply perp-trading-automation skill
│   └─ Infrastructure/dev-ops        → Apply dev-house-ops skill
│
└─► Is it a status update from an agent?
    └─ YES → Log, verify completion, notify user if needed.
```

## 2. Handoff Format

All inter-agent handoffs MUST follow this structure:

```markdown
## HANDOFF: [TASK-ID]

**From:** owl
**To:** [agent-name]
**Priority:** [critical | high | medium | low]
**Deadline:** [timeframe or "none"]

### Task
[Clear, specific description of what needs to be done]

### Context
[Relevant background, prior decisions, constraints]

### Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Output Expected
[What the agent should produce/report back]

### Blockers
[Any known issues or dependencies]
```

## 3. Assigning Tasks

Rules for task assignment:
- **One owner per task.** Never assign the same task to two agents simultaneously.
- **Clear success criteria.** If you can't write what "done" looks like, you're not ready to delegate.
- **Include context.** Agents don't have your full picture. Give them what they need.
- **Set priority.** The crew needs to know what's urgent vs what's queued.
- **Track state.** Use the handoff directory to monitor: pending → in-progress → completed/failed.

## 4. Receiving Handoffs FROM Agents

When an agent completes a task and sends a handoff back:

1. **Validate output** against the success criteria specified in the original task.
2. **If it passes** → Move to completed, merge code if applicable, notify user if user-facing.
3. **If it fails** → Route back to the same agent with specific feedback, or reassign.
4. **If it needs QA** → Route to the appropriate review step before merging.
5. **Log the outcome** for pattern recognition and future optimization.

## 5. Merging PRs After QA Approval

```
QA APPROVAL RECEIVED
│
├─► Review the approval: Is it genuine? Are all checks green?
│   ├─ YES → Proceed with merge
│   └─ NO   → Return to agent with issues
│
├─► Merge strategy:
│   ├─ Clean history → squash merge
│   ├─ Feature branch → merge commit
│   └─ Hotfix → rebase + fast-forward
│
└─► Post-merge:
    ├─ Confirm CI passes on main
    ├─ Notify the requesting agent
    └─ Close the task in tracking
```

## 6. Conflict Resolution

When agents disagree or produce conflicting outputs:

1. **Halt both outputs.** Don't merge anything until resolved.
2. **Identify the conflict.** What exactly disagrees? Is it atechnical difference or a priority difference?
3. **Decide.** OWL makes the final call. Document the decision and rationale.
4. **Communicate.** Tell both agents what was chosen and why.
5. **Prevent recurrence.** Update the relevant skill or config to prevent the same conflict type.

## 7. Priority Scheme

| Level   | Meaning                                      | Response Target |
|---------|----------------------------------------------|-----------------|
| critical| System down, data loss, security issue       | Immediate       |
| high    | User-facing blocker, deadline today          | < 15 min        |
| medium  | Normal task, no immediate blocker            | < 1 hr          |
| low     | Nice-to-have, optimization, cleanup          | < 24 hr         |

## 8. Monitoring & Escalation

- Monitor the handoff directories every 5 minutes (via cron).
- If a task sits pending for > 1 hour without agent pickup → escalate.
- If an agent fails the same task twice → reassign and flag.
- If > 3 tasks are backed up in a queue → alert user and propose triage.
