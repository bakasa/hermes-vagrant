# ============================================================================
# Dev House Operations Skill
# ============================================================================
# Governs how OWL handles infrastructure, deployment, CI/CD,
# and operational tasks for the dev house (GoRides, internal tools, etc.).
# ============================================================================

---

## Scope

This skill covers:
- Infrastructure management (servers, containers, networking)
- CI/CD pipeline oversight
- Deployment orchestration
- Monitoring and alerting
- Environment management (dev, staging, production)
- Dependency and toolchain management

## Operational Principles

1. **Stability first.** No deploy without a rollback plan.
2. **Automate the repeatable.** If you do it twice, script it.
3. **Monitor everything.** If you can't observe it, you can't operate it.
4. **Document changes.** Every infra change gets a log entry.

## Deployment Protocol

```
DEPLOYMENT REQUEST
│
├─► 1. Verify: Is the target environment valid?
├─► 2. Check: Are all tests green on the source branch?
├─► 3. Backup: Snapshot the current production state (DB, configs)
├─► 4. Deploy: Execute the deployment script
├─► 5. Verify: Run smoke tests against the deployed environment
├─► 6. Monitor: Watch health metrics for 10 minutes post-deploy
│
├─ IF ALL PASSES → Confirm deployment, log result
└─ IF ANY FAILS  → Rollback immediately, alert user, investigate
```

## CI/CD Pipeline Standards

- All pipelines must have: build → test → lint → deploy (stag) → deploy (prod)
- No manual steps between stages unless security-sensitive.
- Fail fast: broken builds stop the pipeline immediately.
- Artifact retention: keep last 10 builds per branch.

## Environment Management

| Environment | Purpose                  | Auto-Deploy | Manual Approval |
|-------------|--------------------------|-------------|-----------------|
| dev         | Feature development      | Yes         | No              |
| staging     | Integration testing      | Yes         | No              |
| production  | Live user traffic        | No          | Yes (OWL)       |

## Incident Response

```
INCIDENT DETECTED
│
├─► 1. Assess severity (P0 = total outage, P1 = degraded, P2 = minor)
├─► 2. Notify user immediately for P0/P1
├─► 3. Diagnose: Check logs, metrics, recent changes
├─► 4. Mitigate: Fix or roll back
├─► 5. Resolve and document post-mortem
│
└─ P0: War room mode — all hands, no silence, constant updates
```

## GoRides Specific Operations

- **Ride Service**: Monitor SignalR hub connections, trip state transitions
- **Payment Service**: Track payment processing latency, failure rates
- **API Gateway**: Watch rate limits, auth failures, latency spikes
- **Database**: Monitor query performance, connection pool usage, storage growth

## Toolchain Responsibilities

- Docker / container orchestration
- Git operations (branch management, merge coordination)
- Secret rotation and vault management
- Log aggregation and alerting setup
- SSL certificate renewal
- Backup scheduling and verification
