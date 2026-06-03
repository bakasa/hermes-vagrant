#!/bin/sh
set -e

# Re-create data dirs after Railway volume mount (volume shadows image layer).
mkdir -p \
    /data/.hermes/main \
    /data/.hermes/research \
    /data/.hermes/subconscious \
    /data/.hermes/coder \
    /data/.hermes/qa \
    /data/.hermes/alim \
    /data/handoffs/incoming \
    /data/handoffs/outgoing \
    /data/handoffs/completed \
    /data/handoffs/failed

# Copy agent configs to HERMES_HOME dirs so hermes finds them on first boot.
# Volume mount creates empty dirs — without this, hermes uses default config (no model).
for agent in main research subconscious coder qa alim; do
    src="/app/agents/${agent}/config.yaml"
    dst="/data/.hermes/${agent}/config.yaml"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
    fi
done

# Fix ownership after volume mount (uid 10000 = hermes).
if [ "$(stat -c %u /data 2>/dev/null)" != "10000" ]; then
    chown -R 10000 /data
fi

# Set model for each agent's HERMES_HOME — gateway run reads from state, not CLI flag.
# hermes model set writes to HERMES_HOME/model (or equivalent state file).
for agent in main research subconscious coder qa alim; do
    HERMES_HOME="/data/.hermes/${agent}" hermes model set openrouter/owl-alpha 2>/dev/null || true
done
echo "hermes-crew: model set → openrouter/owl-alpha"

# Railway injects PORT — main agent must bind it (hardcoded 3000 fails health checks).
export PORT="${PORT:-3000}"
echo "hermes-crew: main agent → port ${PORT}"

# supervisord must run as root to setuid per-program (user=hermes in conf).
exec "$@"
