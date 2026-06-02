# Hermes Coder Agent — Dockerfile
FROM python:3.12-slim

LABEL maintainer="hermes-coder"
LABEL description="Coder Agent — delegates to Claude Code, manages PRs, runs tests, ships code."

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    jq \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create workspace
RUN mkdir -p /data/hermes-coder/workspace

WORKDIR /data/hermes-coder

# Copy agent files
COPY SOUL.md .
COPY config.yaml .
COPY skills/ skills/
COPY cron/ cron/

# Install hermes-agent
RUN pip install --no-cache-dir hermes-agent

# Expose gateway port
EXPOSE 3003

# Health check: ensure gateway port responds
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:3003/health || exit 1

# Default: run the hermes gateway
ENTRYPOINT ["hermes", "gateway", "--config", "config.yaml"]
CMD ["--port", "3003"]
