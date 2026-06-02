# Multi-stage build for Subconscious Agent

FROM debian:bookworm-slim AS base

# System dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ripgrep \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent CLI (latest)
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh

# Create agent user
RUN useradd -m -s /bin/bash agent

# App directory
WORKDIR /app
COPY . /app/

# Hermes profile directory
RUN mkdir -p /home/agent/.hermes/profiles/subconscious/{skills,plugins,cron,memories,logs,handoffs/to-main} && \
    chown -R agent:agent /home/agent/.hermes

# Copy config into profile
RUN mkdir -p /home/agent/.hermes/profiles/subconscious/ && \
    cp /app/config.yaml /home/agent/.hermes/profiles/subconscious/config.yaml && \
    cp /app/SOUL.md /home/agent/.hermes/profiles/subconscious/SOUL.md

# Skills
RUN cp -r /app/skills/ /home/agent/.hermes/profiles/subconscious/

# Cron
RUN cp /app/cron/jobs.json /home/agent/.hermes/profiles/subconscious/cron/jobs.json

# Switch to agent user
USER agent
WORKDIR /home/agent

# Expose gateway port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:3002/health || exit 1

# Default command: run the Hermes Agent gateway
CMD ["hermes-agent", "gateway", "--config", "/home/agent/.hermes/profiles/subconscious/config.yaml", "--port", "3002"]
