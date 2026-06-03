# Manage Hermes Crew Agents

Enable or disable agents in the hermes-crew Railway deployment by editing supervisord.railway.conf and triggering a redeploy.

## When to use
- User asks to "enable <agent>", "activate <agent>", "start <agent> agent"
- User asks to "disable <agent>", "deactivate <agent>", "turn off <agent>"
- Valid agents: research, subconscious, coder, qa, alim

## How it works
1. Fetch supervisord.railway.conf from GitHub (bakasa/hermes-vagrant)
2. Toggle `autostart=false` ↔ `autostart=true` for the target agent
3. Push the change back to GitHub
4. Trigger Railway redeploy via GraphQL API

## Execute with execute_code tool

```python
import os, base64, json, urllib.request

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
AGENT = "coder"   # change to target agent
ACTION = "enable"  # "enable" or "disable"

# Step 1: Fetch file from GitHub
req = urllib.request.Request(
    "https://api.github.com/repos/bakasa/hermes-vagrant/contents/supervisord.railway.conf",
    headers={"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}
)
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
sha = data["sha"]
content = base64.b64decode(data["content"]).decode()

# Step 2: Toggle autostart for target agent
old = f"[program:hermes-{AGENT}]"
if ACTION == "enable":
    # Find the program block and flip autostart
    lines = []
    in_block = False
    for line in content.splitlines():
        if line.strip() == old:
            in_block = True
        if in_block and line.strip().startswith("autostart=false"):
            line = line.replace("autostart=false", "autostart=true")
            in_block = False
        lines.append(line)
    new_content = "\n".join(lines) + "\n"
else:  # disable
    lines = []
    in_block = False
    for line in content.splitlines():
        if line.strip() == old:
            in_block = True
        if in_block and line.strip().startswith("autostart=true"):
            line = line.replace("autostart=true", "autostart=false")
            in_block = False
        lines.append(line)
    new_content = "\n".join(lines) + "\n"

# Verify change was made
if new_content == content:
    print(f"WARNING: No change made — {AGENT} might already be {ACTION}d")
else:
    print(f"Changed autostart for hermes-{AGENT} → {'true' if ACTION=='enable' else 'false'}")

# Step 3: Push to GitHub
payload = json.dumps({
    "message": f"chore: {ACTION} hermes-{AGENT} agent",
    "content": base64.b64encode(new_content.encode()).decode(),
    "sha": sha
}).encode()
req2 = urllib.request.Request(
    "https://api.github.com/repos/bakasa/hermes-vagrant/contents/supervisord.railway.conf",
    data=payload, method="PUT",
    headers={"Authorization": f"token {GITHUB_TOKEN}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req2) as r:
    result = json.loads(r.read())
print("GitHub pushed:", result["commit"]["sha"][:8])

# Step 4: Trigger Railway redeploy
RAILWAY_TOKEN = os.environ.get("RAILWAY_API_TOKEN", "")
if not RAILWAY_TOKEN:
    print("No RAILWAY_API_TOKEN set — push done but redeploy must be triggered manually")
else:
    gql_payload = json.dumps({"query": """
        mutation {
          environmentTriggersDeploy(input: {
            projectId: "f4a0f3ee-f69d-4573-a6e5-146362198454"
            environmentId: "5098f54b-41cf-4668-b6f7-7778ac37a47e"
            serviceId: "5acf2f58-6ae4-4dbf-a953-1fe60c3a8f72"
          })
        }
    """}).encode()
    req3 = urllib.request.Request(
        "https://backboard.railway.app/graphql/v2",
        data=gql_payload,
        headers={"Authorization": f"Bearer {RAILWAY_TOKEN}",
                 "Content-Type": "application/json",
                 "User-Agent": "railway-cli/3.0.0"}
    )
    with urllib.request.urlopen(req3) as r:
        deploy_result = json.loads(r.read())
    print("Railway redeploy triggered:", deploy_result.get("data", {}).get("environmentTriggersDeploy"))

print(f"Done — hermes-{AGENT} will be {ACTION}d after redeploy (~3 min)")
```

## Notes
- Redeploy takes ~3 minutes (Docker build + start)
- RAILWAY_API_TOKEN must be set as env var on hermes-crew for auto-redeploy
- If no RAILWAY_API_TOKEN, GitHub is updated but redeploy must be triggered manually
- All 5 secondary agents start disabled: research, subconscious, coder, qa, alim
