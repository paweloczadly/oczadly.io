#!/usr/bin/env bash

set -euo pipefail

VERSION="${1:-1.0.0}"

if [ -z "${GRADLE_USER_HOME:-}" ]; then
GRADLE_USER_HOME="$HOME/.gradle"
fi

INITD_DIR="$GRADLE_USER_HOME/init.d"
INIT_FILE="$INITD_DIR/spring-initializr.gradle"

CONTENT="plugins {
id 'io.oczadly.springinitializr' version '${VERSION}'
}
"

if [ ! -d "$INITD_DIR" ]; then
mkdir -p "$INITD_DIR"
echo "Created directory: $INITD_DIR"
fi

if [ ! -f "$INIT_FILE" ] || ! grep -q "io.oczadly.springinitializr" "$INIT_FILE"; then
echo "$CONTENT" > "$INIT_FILE"
echo "Created or updated: $INIT_FILE"
else
echo "File already exists and contains the required plugin: $INIT_FILE"
fi
