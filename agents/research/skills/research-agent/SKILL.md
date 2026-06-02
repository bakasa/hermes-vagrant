# Research Agent — SKILL.md

## Purpose

This skill defines the Research Agent's vault-based research methodology. It covers how to scan sources, extract findings, evaluate claims, maintain dossiers, and route signals to other agents.

## Agent Identity

- **Name:** Research Agent
- **Port:** 3001
- **Vault Path:** `/data/.hermes/research/vault/`
- **Handoff Path:** `/data/handoffs/`

## Vault Structure

```
vault/
├── findings/       # Individual research findings (one per file)
│   └── YYYY-MM-DD-{topic}-finding-{id}.md
├── claims/         # Evaluated claims with evidence ratings
│   └── YYYY-MM-DD-{claim-slug}.md
├── sources/        # Source metadata and reliability scores
│   └── {source-id}.json
└── dossiers/       # Topic-aggregated research dossiers
    └── {topic-slug}.md
```

## Workflow

### 1. Daily Research Scan (06:00 UTC)

Run the daily scan across all configured sources:

1. Scan RSS feeds listed in `references/feed-list.md`
2. Query arXiv for recent papers in configured categories
3. Check Semantic Scholar for trending papers
4. Review configured search queries (see `references/search-queries.md`)
5. Log all new findings to `vault/findings/`
6. Update source reliability scores in `vault/sources/`
7. Generate daily digest handoff to Main agent

**Output:** `vault/digests/YYYY-MM-DD-daily-digest.md`

### 2. Extract Cycle (Every 6 Hours)

Between daily scans, run a lighter extract cycle:

1. Check for new entries since last scan
2. Extract key claims from new findings
3. Cross-reference against existing claims
4. Flag contradictions or confirmations
5. Route urgent signals immediately

### 3. Claim Evaluation

When evaluating a claim:

1. Search vault for existing evidence
2. Query sources for corroboration
3. Assign confidence level: HIGH / MEDIUM / LOW / UNVERIFIED
4. Document reasoning chain
5. Write to `vault/claims/`
6. If claim contradicts existing knowledge, flag for review

### 4. Dossier Maintenance

Dossiers are living documents that aggregate all research on a topic:

1. Create new dossier when a topic accumulates 3+ findings
2. Update dossiers when new findings relate to existing topics
3. Include: summary, key findings, open questions, source list
4. Cross-link to related dossiers

### 5. Signal Routing (Handoff Protocol)

When a finding is significant enough to share:

**Handoff JSON Schema:**
```json
{
  "schema_version": "1.0",
  "from": "research",
  "to": "<target-agent>",
  "type": "<signal-type>",
  "priority": "<urgent|high|normal|low>",
  "subject": "<brief subject>",
  "body": "<structured summary>",
  "sources": [
    {
      "title": "<source title>",
      "url": "<source url>",
      "type": "<paper|blog|news|repo>",
      "date": "<YYYY-MM-DD>",
      "reliability": "<high|medium|low>"
    }
  ],
  "tags": ["<tag1>", "<tag2>"],
  "confidence": "<HIGH|MEDIUM|LOW|UNVERIFIED>",
  "created_at": "<ISO-8601 timestamp>"
}
```

**Handoff Targets:**
- `main` — Daily digests, urgent signals, cross-cutting research
- `coder` — Research-backed feature requests, tech feasibility
- `qa` — Known issues, upstream bug reports, test-relevant findings
- `subconscious` — Raw patterns, anomalies, trend data

## Source Evaluation Criteria

Score sources on reliability:

| Score | Criteria |
|-------|----------|
| HIGH | Peer-reviewed, reproducible, multiple corroborating sources |
| MEDIUM | Credible institution/author, single source, no contradictions |
| LOW | Unverified, preprint without review, potential bias |
| UNVERIFIED | Single unverified source, preliminary |

## Finding Template

```markdown
# Finding: {title}

- **ID:** {YYYY-MM-DD}-F{id}
- **Date:** {YYYY-MM-DD}
- **Topic:** {topic-tag}
- **Confidence:** {HIGH|MEDIUM|LOW|UNVERIFIED}
- **Source(s):** [{title}]({url})
- **Type:** {paper|blog|news|repo|preprint}

## Summary

{2-3 sentence executive summary}

## Key Points

- {point 1}
- {point 2}
- {point 3}

## Raw Extract

> {direct quote or data point}

## Implications

{Why this matters to the crew}

## Related Findings

- {link to related finding}
```

## Claim Template

```markdown
# Claim: {claim-statement}

- **ID:** {YYYY-MM-DD}-C{id}
- **Date:** {YYYY-MM-DD}
- **Status:** {SUPPORTED|CONTRADICTED|UNVERIFIED|UNDER_REVIEW}
- **Confidence:** {HIGH|MEDIUM|LOW}
- **Topic:** {topic-tag}

## Evidence For

- [{source title}]({url}) — {summary of supporting evidence}

## Evidence Against

- [{source title}]({url}) — {summary of contradicting evidence}

## Assessment

{Reasoning chain. Why this confidence level? What would change it?}

## Related Claims

- {link to related claim}
```

## Dossier Template

```markdown
# Dossier: {topic}

- **Created:** {YYYY-MM-DD}
- **Last Updated:** {YYYY-MM-DD}
- **Status:** {ACTIVE|PAUSED|ARCHIVED}
- **Finding Count:** {n}

## Executive Summary

{High-level overview of what we know about this topic}

## Key Findings

### {Finding Title} ({date})
{summary}

## Open Questions

- {question 1} — {why it matters}
- {question 2} — {why it matters}

## Source Inventory

| Source | Type | Date | Reliability |
|--------|------|------|-------------|
| {title} | {type} | {date} | {score} |

## Related Dossiers

- {link to related dossier}
```

## Search & Discovery

### arXiv Queries

Use the arXiv API for structured queries:
```
https://export.arxiv.org/api/query?search_query=cat:cs.AI+AND+abs:keyword&sortBy=submittedDate&sortOrder=descending&max_results=20
```

### RSS Feed Parsing

Parse feeds from `references/feed-list.md`. For each feed:
1. Fetch feed XML
2. Extract entries since last scan date
3. Classify by topic tags
4. Create findings for significant entries

### Web Search Queries

Use templates from `references/search-queries.md` for structured web discovery.

## Conflict Resolution

When sources contradict:
1. Log both claims with their evidence
2. Assign confidence based on source reliability
3. Flag the contradiction explicitly
4. Note what evidence would resolve the conflict
5. Schedule follow-up scan for resolution

## Vault Hygiene

- Archive findings older than 90 days to `vault/archive/`
- Merge duplicate findings
- Retire claims that have been superseded
- Update source reliability scores quarterly
- Prune handoff directory weekly
