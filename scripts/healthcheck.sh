#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$root_dir"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

echo "Checking containers..."
docker compose ps

echo "Checking gateway..."
if ! curl -fsS http://127.0.0.1:5446 >/dev/null; then
  echo "Gateway check failed on 127.0.0.1:5446" >&2
  exit 1
fi

echo "Checking LocalStack health..."
if ! curl -fsS http://127.0.0.1:4566/_localstack/health >/dev/null; then
  echo "LocalStack health endpoint not reachable" >&2
  exit 1
fi

echo "OK"
