# Template for new Hermes agent
# Placeholders: {{AGENT_NAME}}, {{AGENT_PORT}}, {{AGENT_ROLE}}
# These are replaced by scripts/add-agent.sh — NOT Docker ARGs.

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    AGENT_NAME={{AGENT_NAME}} \
    GATEWAY_PORT={{AGENT_PORT}} \
    AGENT_ROLE={{AGENT_ROLE}} \
    HERMES_HOME=/data/.hermes \
    TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git ca-certificates unzip jq \
    python3 python3-pip python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash hermes && \
    echo "hermes ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hermes && \
    chmod 0440 /etc/sudoers.d/hermes

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh

RUN mkdir -p /data/handoffs /data/.hermes && chown -R hermes:hermes /data

COPY --chown=hermes:hermes . /data/agent/

USER hermes
WORKDIR /data/agent

EXPOSE {{AGENT_PORT}}

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD-SHELL curl -sf http://localhost:{{AGENT_PORT}}/health || exit 0

CMD ["hermes", "gateway", "start", "--port", "{{AGENT_PORT}}"]
