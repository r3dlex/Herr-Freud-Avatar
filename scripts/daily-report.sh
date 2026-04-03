#!/bin/bash
# Generate a daily session report

echo "=== Herr Freud Daily Report ==="
echo "Date: $(date -u +%Y-%m-%d)"
echo ""

if [ -d "data/sessions" ]; then
    TODAY=$(date +%Y-%m-%d)
    TODAY_FILES=$(find data/sessions -name "${TODAY}_*.md" 2>/dev/null | wc -l)

    echo "Sessions today: $TODAY_FILES"

    if [ "$TODAY_FILES" -gt 0 ]; then
        echo ""
        echo "Session files:"
        find data/sessions -name "${TODAY}_*.md" -exec basename {} \;
    fi
else
    echo "No sessions directory found"
fi

echo ""

if [ -d "data/nudges" ]; then
    TODAY_NUDGES=$(find data/nudges -name "${TODAY}_nudge.md" 2>/dev/null | wc -l)
    echo "Nudges sent today: $TODAY_NUDGES"
fi

echo ""
echo "=== End Report ==="
