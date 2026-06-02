# Hermes Main Agent (OWL) — Container Image
FROM debian:bookworm-slim AS base

LABEL maintainer="ZOO Company"
LABEL description="Hermes Main Agent — OWL Coordinator & Slack Gateway"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    AGENT_HOME=/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${AGENT_HOME}

# Copy agent files
COPY . ${AGENT_HOME}/

# Ensure handoff directories exist
RUN mkdir -p /data/handoffs/{incoming,outgoing,completed,failed} && \
    mkdir -p /data/.hermes/logs

# Expose gateway port
EXPOSE 3000

# Health check — verify the gateway is responding
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -sf http://localhost:3000/health || exit 1

# Run the agent
ENTRYPOINT ["python3", "-m", "hermes_agent"]
CMD ["--config", "config.yaml"]
