# Alim Agent — Hermes Agent (Alimiyyah Study Companion)
# Part of the Hermes Agent framework by Nous Research

FROM python:3.12-slim

LABEL maintainer="Nous Research"
LABEL description="Alim Agent — Islamic studies companion for Alimiyyah program students"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# ---- System dependencies ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- Python dependencies ----
RUN pip install --no-cache-dir --upgrade pip

# Google Classroom API client
RUN pip install --no-cache-dir \
    google-api-python-client==2.127.0 \
    google-auth-httplib2==0.2.0 \
    google-auth-oauthlib==1.2.0

# Core runtime
RUN pip install --no-cache-dir \
    pyyaml==6.0.1 \
    pydantic==2.7.1 \
    requests==2.31.0 \
    watchfiles==0.21.0

# ---- Copy application code ----
COPY . /app

# ---- Create directories ----
RUN mkdir -p /app/knowledge \
    /app/skills \
    /app/cron \
    /app/plugins \
    /app/memories \
    /app/logs

# ---- Set Python path ----
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# ---- Expose port ----
EXPOSE 3005

# ---- Health check ----
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:3005/health || exit 1

# ---- Default command ----
CMD ["python", "-m", "hermes_alim", "serve", "--config", "config.yaml"]
