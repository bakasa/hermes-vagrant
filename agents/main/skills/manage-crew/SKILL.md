# Manage Hermes Crew Agents

Enable or disable agents in the hermes-crew deployment by modifying their autostart config and restarting.
Auto-detects whether running on Railway (GitHub API + redeploy) or local Docker Compose (docker socket).

## When to use
- User asks to "enable <agent>", "activate <agent>", "start <agent> agent"
- User asks to "disable <agent>", "deactivate <agent>", "turn off <agent>"
- User asks "which agents are running?" or "agent status"
- Valid agents: research, subconscious, coder, qa, alim

## Execute with execute_code tool

```python
import os, base64, json, urllib.request, subprocess

AGENT = "coder"   # set to target agent name
ACTION = "enable"  # "enable" or "disable"

IS_RAILWAY = bool(os.environ.get("RAILWAY_PROJECT_ID"))
IS_LOCAL = os.path.exists("/var/run/docker.sock")

# ── LOCAL: Docker socket path ─────────────────────────────────────────────
if IS_LOCAL:
    container = f"hermes-{AGENT}"
    if ACTION == "enable":
        r = subprocess.run(
            ["docker", "compose", "up", "-d", container],
            cwd="/app", capture_output=True, text=True
        )
        print(r.stdout or r.stderr)
        print(f"hermes-{AGENT} started")
    else:
        r = subprocess.run(
            ["docker", "compose", "stop", container],
            cwd="/app", capture_output=True, text=True
        )
        print(r.stdout or r.stderr)
        print(f"hermes-{AGENT} stopped")

# ── RAILWAY: GitHub API + redeploy ────────────────────────────────────────
elif IS_RAILWAY:
    GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
    RAILWAY_TOKEN = os.environ.get("RAILWAY_API_TOKEN", "")

    # Fetch supervisord.railway.conf
    req = urllib.request.Request(
        "https://api.github.com/repos/bakasa/hermes-vagrant/contents/supervisord.railway.conf",
        headers={"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}
    )
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read())
    sha = data["sha"]
    content = base64.b64decode(data["content"]).decode()

    # Toggle autostart in the right program block
    block_marker = f"[program:hermes-{AGENT}]"
    lines, in_block = [], False
    changed = False
    for line in content.splitlines():
        if line.strip() == block_marker:
            in_block = True
        if in_block:
            if ACTION == "enable" and line.strip() == "autostart=false":
                line = line.replace("autostart=false", "autostart=true")
                in_block = False
                changed = True
            elif ACTION == "disable" and line.strip() == "autostart=true":
                line = line.replace("autostart=true", "autostart=false")
                in_block = False
                changed = True
        lines.append(line)
    new_content = "\n".join(lines) + "\n"

    if not changed:
        print(f"hermes-{AGENT} already {ACTION}d — no change needed")
    else:
        # Push to GitHub
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
        print(f"GitHub updated: {result['commit']['sha'][:8]}")

        # Trigger Railway redeploy
        if RAILWAY_TOKEN:
            gql = json.dumps({"query": """mutation { environmentTriggersDeploy(input: {
                projectId: "f4a0f3ee-f69d-4573-a6e5-146362198454"
                environmentId: "5098f54b-41cf-4668-b6f7-7778ac37a47e"
                serviceId: "5acf2f58-6ae4-4dbf-a953-1fe60c3a8f72"
            }) }"""}).encode()
            req3 = urllib.request.Request(
                "https://backboard.railway.app/graphql/v2", data=gql,
                headers={"Authorization": f"Bearer {RAILWAY_TOKEN}",
                         "Content-Type": "application/json", "User-Agent": "railway-cli/3.0.0"}
            )
            with urllib.request.urlopen(req3) as r:
                print("Railway redeploy triggered:", json.loads(r.read()).get("data", {}).get("environmentTriggersDeploy"))
            print(f"hermes-{AGENT} will be {ACTION}d in ~3 min")
        else:
            print("RAILWAY_API_TOKEN not set — push done but redeploy must be triggered manually")
else:
    print("ERROR: Not on Railway and no Docker socket found at /var/run/docker.sock")
```

## Agent status check

```python
import os, subprocess, urllib.request, json

IS_LOCAL = os.path.exists("/var/run/docker.sock")
if IS_LOCAL:
    r = subprocess.run(["docker", "compose", "ps", "--format", "json"],
        cwd="/app", capture_output=True, text=True)
    print(r.stdout)
else:
    print("Railway: check Railway dashboard or deployment logs for agent status")
```

## Notes
- **Local**: uses `/var/run/docker.sock` — mount it in docker-compose.yml for hermes-main (already done)
- **Railway**: uses GitHub API + RAILWAY_API_TOKEN env var — already configured
- Redeploy takes ~3 min on Railway; local Docker starts in seconds
- `cwd="/app"` assumes docker-compose.yml is at /app in container
