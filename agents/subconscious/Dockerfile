# Subconscious Agent — Pattern Incubator
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    GATEWAY_PORT=3002

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ripgrep python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent CLI
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh

RUN mkdir -p /data/handoffs /data/.hermes && chmod -R 777 /data

WORKDIR /app

COPY . /app/

EXPOSE 3002

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD-SHELL curl -sf http://localhost:3002/health || exit 0

CMD ["hermes", "gateway", "start", "--port", "3002"]
