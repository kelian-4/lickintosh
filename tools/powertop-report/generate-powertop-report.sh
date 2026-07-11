#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="/tmp/shell-gemini"
OUTPUT_FILE="$OUTPUT_DIR/powertop-report.csv"

mkdir -p "$OUTPUT_DIR"

powertop --csv="$OUTPUT_FILE" --time=8

chmod 644 "$OUTPUT_FILE"
