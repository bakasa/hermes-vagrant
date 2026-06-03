# Manage Hermes Crew — Runtime Agent Orchestration

Spawn, enable, disable, and inspect agents at runtime via supervisorctl.
No Docker rebuild or redeploy needed — changes take effect in seconds.
New agents persist across restarts via /data/supervisor.d/ (volume-backed).

## Commands OWL supports

| User says | Action |
|---|---|
| "enable coder" | supervisorctl start hermes-coder |
| "disable research" | supervisorctl stop hermes-research |
| "agent status" / "crew status" | supervisorctl status |
| "create agent <name>: <description>" | scaffold + supervisorctl update |
| "remove agent <name>" | supervisorctl stop + remove .conf |

---

## Enable / Disable existing agent (instant)

```python
import subprocess

AGENT = "coder"   # research | subconscious | coder | qa | alim
ACTION = "start"  # start | stop | restart

r = subprocess.run(
    ["sudo", "supervisorctl", ACTION, f"hermes-{AGENT}"],
    capture_output=True, text=True
)
print(r.stdout or r.stderr)
```

---

## Agent status

```python
import subprocess
r = subprocess.run(["sudo", "supervisorctl", "status"], capture_output=True, text=True)
print(r.stdout)
```

---

## Create a brand new agent (spawns immediately, persists across restarts)

```python
import os, subprocess

AGENT_NAME = "trader"          # lowercase, hyphens ok
AGENT_ROLE = "Crypto Trader"   # human-readable role
AGENT_SOUL = """You are the Trader agent in the Hermes crew.
Your role: monitor markets, execute trades, report to OWL.
Specialties: crypto trading, market analysis, risk management."""

# 1. Scaffold agent directory on volume
agent_dir = f"/data/agents/{AGENT_NAME}"
hermes_home = f"/data/.hermes/{AGENT_NAME}"
os.makedirs(agent_dir, exist_ok=True)
os.makedirs(hermes_home, exist_ok=True)

# 2. Write SOUL.md
with open(f"{agent_dir}/SOUL.md", "w") as f:
    f.write(f"# {AGENT_ROLE}\n\n{AGENT_SOUL}\n")

# 3. Write config.yaml (copy main agent pattern)
config = f"""agent:
  name: "{AGENT_NAME}"
  role: "{AGENT_ROLE}"

openrouter:
  api_key: "${{OPENROUTER_API_KEY}}"

providers:
  openrouter:
    base_url: "https://openrouter.ai/api/v1"
    api_key: "${{OPENROUTER_API_KEY}}"

gateway:
  host: "0.0.0.0"
  mode: "slack"

slack:
  bot_token: "${{SLACK_BOT_TOKEN}}"
  app_token: "${{SLACK_APP_TOKEN}}"

handoff:
  incoming_dir: "/data/handoffs/incoming"
  outgoing_dir: "/data/handoffs/outgoing"
  completed_dir: "/data/handoffs/completed"
  failed_dir: "/data/handoffs/failed"
"""
with open(f"{agent_dir}/config.yaml", "w") as f:
    f.write(config)

# 4. Set model via hermes config set
env = dict(os.environ)
env["HERMES_HOME"] = hermes_home
env["HOME"] = "/data"
subprocess.run(["/usr/local/bin/hermes", "config", "set", "model", "openrouter/owl-alpha"],
    env=env, capture_output=True)

# 5. Fix ownership (hermes uid=10000)
subprocess.run(["chown", "-R", "10000:10000", agent_dir, hermes_home])

# 6. Write supervisord .conf to /data/supervisor.d/ (persists via volume)
conf = f"""[program:hermes-{AGENT_NAME}]
command=hermes gateway run
directory={agent_dir}
user=hermes
autostart=true
autorestart=true
startretries=5
startsecs=10
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
environment=HOME="/data",HERMES_HOME="{hermes_home}",AGENT_NAME="{AGENT_NAME}",OPENROUTER_API_KEY="%(ENV_OPENROUTER_API_KEY)s",SLACK_BOT_TOKEN="%(ENV_SLACK_BOT_TOKEN)s",SLACK_APP_TOKEN="%(ENV_SLACK_APP_TOKEN)s",SLACK_ALLOWED_USERS="%(ENV_SLACK_ALLOWED_USERS)s"
"""
conf_path = f"/data/supervisor.d/hermes-{AGENT_NAME}.conf"
with open(conf_path, "w") as f:
    f.write(conf)

# 7. Tell supervisord to pick up the new process (no restart of existing agents)
r = subprocess.run(["sudo", "supervisorctl", "reread"], capture_output=True, text=True)
print("reread:", r.stdout.strip())
r2 = subprocess.run(["sudo", "supervisorctl", "update"], capture_output=True, text=True)
print("update:", r2.stdout.strip())

# 8. Verify it started
r3 = subprocess.run(["sudo", "supervisorctl", "status", f"hermes-{AGENT_NAME}"],
    capture_output=True, text=True)
print("status:", r3.stdout.strip())
print(f"\nAgent hermes-{AGENT_NAME} spawned. It will survive restarts.")
```

---

## Remove an agent

```python
import os, subprocess

AGENT_NAME = "trader"
subprocess.run(["sudo", "supervisorctl", "stop", f"hermes-{AGENT_NAME}"], capture_output=True)
conf_path = f"/data/supervisor.d/hermes-{AGENT_NAME}.conf"
if os.path.exists(conf_path):
    os.remove(conf_path)
subprocess.run(["sudo", "supervisorctl", "reread"], capture_output=True)
subprocess.run(["sudo", "supervisorctl", "update"], capture_output=True)
print(f"hermes-{AGENT_NAME} removed")
```

---

## Notes
- supervisorctl socket at `/tmp/supervisor.sock` requires sudo (hermes user has NOPASSWD sudo)
- `/data/supervisor.d/` is on the persistent volume — new agents survive Docker restarts
- `/data/agents/<name>/` holds SOUL.md + config.yaml on volume
- Pre-built agents (research, coder, etc.) are in `/app/agents/` in the image
- Creating a new agent takes ~5 seconds; no rebuild, no redeploy
