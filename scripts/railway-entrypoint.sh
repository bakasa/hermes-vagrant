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

# Fix ownership after volume mount (uid 10000 = hermes).
if [ "$(stat -c %u /data 2>/dev/null)" != "10000" ]; then
    chown -R 10000 /data
fi

# Railway injects PORT — main agent must bind it (hardcoded 3000 fails health checks).
# Other agents use fixed internal ports (3001-3005); they're not Railway-exposed.
export PORT="${PORT:-3000}"

echo "hermes-crew: main agent → port ${PORT}"
echo "hermes-crew: internal agents → research:3001 subconscious:3002 coder:3003 qa:3004 alim:3005"

# supervisord must run as root to setuid per-program (user=hermes in conf).
exec "$@"
