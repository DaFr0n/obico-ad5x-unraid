#!/bin/sh
set -eu

if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl not found." >&2
    exit 1
fi

openssl rand -hex 32
