FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    GATEWAY_PORT=3004

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

EXPOSE 3004

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD-SHELL curl -sf http://localhost:3004/health || exit 0

CMD ["hermes", "gateway", "start", "--port", "3004"]
