#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
custom_file="$root_dir/.custom_secrets.txt"

if [ -f "$custom_file" ]; then
  set -a
  . "$custom_file"
  set +a
fi

: "${AWS_ACCESS_KEY_ID:=$(openssl rand -hex 16)}"
: "${AWS_SECRET_ACCESS_KEY:=$(openssl rand -hex 16)}"
: "${DB_USERNAME:=$(openssl rand -hex 16)}"
: "${DB_PASSWORD:=$(openssl rand -hex 16)}"

if [ -z "${ACME_EMAIL:-}" ]; then
  echo "Set ACME_EMAIL in .custom_secrets.txt or environment" >&2
  exit 1
fi
if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
  echo "Set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN in .custom_secrets.txt or environment" >&2
  exit 1
fi
if [ -z "${APP_DOMAIN:-}" ]; then
  echo "Set APP_DOMAIN in .custom_secrets.txt or environment" >&2
  exit 1
fi

SANDBOX_IMAGE="${SANDBOX_IMAGE:-${DOCKER_IMAGE:-}}"
if [ -z "${SANDBOX_IMAGE:-}" ]; then
  echo "Set SANDBOX_IMAGE (or DOCKER_IMAGE) in .custom_secrets.txt or environment" >&2
  exit 1
fi

APP_NAMESPACE="${APP_NAMESPACE:-iac-sandbox-prod}"
GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-nginx-gateway}"
GATEWAY_SERVICE="${GATEWAY_SERVICE:-global-gateway-nginx}"

ACME_MODE="${ACME_MODE:-prod}"
case "$ACME_MODE" in
  staging)
    ACME_ISSUER_NAME="${ACME_ISSUER_NAME:-letsencrypt-staging}"
    ACME_SERVER="${ACME_SERVER:-https://acme-staging-v02.api.letsencrypt.org/directory}"
    ;;
  prod)
    ACME_ISSUER_NAME="${ACME_ISSUER_NAME:-letsencrypt-prod}"
    ACME_SERVER="${ACME_SERVER:-https://acme-v02.api.letsencrypt.org/directory}"
    ;;
  *)
    echo "ACME_MODE must be 'staging' or 'prod'" >&2
    exit 1
    ;;
esac
ACME_ACCOUNT_SECRET="${ACME_ACCOUNT_SECRET:-${ACME_ISSUER_NAME}-account-key}"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export DB_USERNAME
export DB_PASSWORD
export ACME_EMAIL
export ACME_ISSUER_NAME
export ACME_SERVER
export ACME_ACCOUNT_SECRET
export APP_DOMAIN
export APP_NAMESPACE
export SANDBOX_IMAGE

auth_b64="$(printf '%s:%s' "$DOCKERHUB_USERNAME" "$DOCKERHUB_TOKEN" | base64 | tr -d '\n')"
DOCKER_CONFIG_JSON="$(printf '{\"auths\":{\"https://index.docker.io/v1/\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}' \
  "$DOCKERHUB_USERNAME" "$DOCKERHUB_TOKEN" "${DOCKERHUB_EMAIL:-}" "$auth_b64")"
export DOCKER_CONFIG_JSON

envsubst < "$root_dir/k8s/prod/apply.yaml" | kubectl apply -f -

if [ -n "${PUBLIC_IP:-}" ]; then
  if kubectl -n "$GATEWAY_NAMESPACE" get svc "$GATEWAY_SERVICE" >/dev/null 2>&1; then
    kubectl -n "$GATEWAY_NAMESPACE" patch svc "$GATEWAY_SERVICE" \
      --type merge \
      -p "{\"spec\":{\"externalIPs\":[\"$PUBLIC_IP\"]}}"
  else
    echo "Gateway Service $GATEWAY_NAMESPACE/$GATEWAY_SERVICE not found; skipping externalIP patch" >&2
  fi
fi
