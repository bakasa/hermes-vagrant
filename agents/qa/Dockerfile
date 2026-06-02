FROM python:3.12-slim

LABEL maintainer="hermes-qa"
LABEL description="QA Agent — quality gatekeeper for PR reviews and security scans"

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose gateway port
EXPOSE 3004

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:3004/health || exit 1

# Run the gateway
CMD ["python", "-m", "gateway"]
