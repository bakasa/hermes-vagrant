# Alim Agent — Hermes Agent (Alimiyyah Study Companion)
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    GATEWAY_PORT=3005

WORKDIR /app

# System dependencies + Google Classroom API
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl git libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        google-api-python-client==2.127.0 \
        google-auth-httplib2==0.2.0 \
        google-auth-oauthlib==1.2.0 \
        pyyaml==6.0.1 \
        pydantic==2.7.1 \
        requests==2.31.0 \
        watchfiles==0.21.0

# Copy application code
COPY . /app

# Create directories
RUN mkdir -p /app/knowledge /app/skills /app/cron /app/plugins /app/memories /app/logs

EXPOSE 3005

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD-SHELL curl -sf http://localhost:3005/health || exit 0

CMD ["hermes", "gateway", "start", "--port", "3005"]
