# Hermes Main Agent (OWL) — Container Image
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    AGENT_HOME=/app \
    GATEWAY_PORT=3000

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv curl jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${AGENT_HOME}

# Copy agent files
COPY . ${AGENT_HOME}/

# Ensure directories exist
RUN mkdir -p /data/handoffs /data/.hermes/logs

EXPOSE 3000

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD-SHELL curl -sf http://localhost:3000/health || exit 0

CMD ["hermes", "gateway", "start", "--port", "3000"]
