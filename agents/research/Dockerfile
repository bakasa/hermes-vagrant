# Hermes Research Agent — Dockerfile
# Port: 3001
# Evidence Collector & Signal Router

FROM debian:bookworm-slim AS base

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git ca-certificates unzip jq \
    python3 python3-pip python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create hermes user with sudo
RUN useradd -m -s /bin/bash hermes && \
    echo "hermes ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hermes && \
    chmod 0440 /etc/sudoers.d/hermes

# Install Hermes Agent CLI
ARG HERMES_VERSION=latest
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh

# Evidence vault directory
RUN mkdir -p /data/.hermes/research/vault/{findings,claims,sources,dossiers} \
    && chown -R hermes:hermes /data/.hermes

# Handoff directory
RUN mkdir -p /data/handoffs && chown hermes:hermes /data/handoffs

# Hermes home
RUN mkdir -p /data/.hermes && chown hermes:hermes /data/.hermes

# Agent workspace
RUN mkdir -p /data/hermes-research && chown hermes:hermes /data/hermes-research

USER hermes
WORKDIR /data/hermes-research

# Copy agent files
COPY --chown=hermes:hermes . /data/hermes-research/

# Research Agent gateway port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=120s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 0

# Environment
ENV GATEWAY_PORT=3001
ENV AGENT_NAME=research
ENV AGENT_ROLE="Research Agent"
ENV HERMES_HOME=/data/.hermes
ENV TZ=UTC

# Start Hermes gateway
CMD ["hermes", "gateway", "start", "--port", "3001"]
