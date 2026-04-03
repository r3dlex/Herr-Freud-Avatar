#!/bin/bash
set -e

echo "=== Herr Freud Health Check ==="

# Check process
if ! pgrep -x "beam.smp" > /dev/null 2>&1; then
    echo "WARNING: Herr Freud process (beam) not running"
    exit 1
fi

echo "✓ Process running"

# Check database
if [ -f "priv/herr_freud.db" ]; then
    echo "✓ Database exists"
else
    echo "WARNING: Database not found"
fi

# Check data directories
for dir in data/input data/sessions data/nudges; do
    if [ -d "$dir" ]; then
        echo "✓ $dir exists"
    else
        echo "WARNING: $dir not found"
    fi
done

# Check IAMQ connectivity
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18790/health 2>/dev/null | grep -q "200"; then
    echo "✓ IAMQ HTTP reachable"
else
    echo "WARNING: IAMQ HTTP not reachable (is iamq-sidecar running?)"
fi

echo ""
echo "=== Health Check Complete ==="
