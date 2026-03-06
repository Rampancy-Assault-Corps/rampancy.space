#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="${ROOT_DIR}/rampancy_assault_corps_server"
WEB_DIR="${ROOT_DIR}/rampancy_assault_corps_web"
LOCAL_ENV_FILE="${RAC_LOCAL_ENV_FILE:-${ROOT_DIR}/config/local.env}"

if [[ -f "${LOCAL_ENV_FILE}" ]]; then
  set -a
  source "${LOCAL_ENV_FILE}"
  set +a
  echo "[local_dev] loaded env file ${LOCAL_ENV_FILE}"
fi

GATEWAY_HOST="${RAC_GATEWAY_HOST:-127.0.0.1}"
GATEWAY_PORT="${RAC_GATEWAY_PORT:-8080}"
BACKEND_PORT="${RAC_BACKEND_PORT:-8081}"
FRONTEND_PORT="${RAC_FRONTEND_PORT:-8082}"

BACKEND_PID=""
FRONTEND_PID=""
GATEWAY_PID=""

cleanup() {
  pkill -P "$$" >/dev/null 2>&1 || true
  if [[ -n "${GATEWAY_PID}" ]]; then
    kill "${GATEWAY_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${FRONTEND_PID}" ]]; then
    kill "${FRONTEND_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${BACKEND_PID}" ]]; then
    kill "${BACKEND_PID}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT INT TERM

echo "[local_dev] starting backend on :${BACKEND_PORT}"
(
  cd "${SERVER_DIR}"
  PORT="${BACKEND_PORT}" dart run lib/main.dart
) &
BACKEND_PID="$!"

echo "[local_dev] starting web on :${FRONTEND_PORT}"
(
  cd "${WEB_DIR}"
  jaspr serve -p "${FRONTEND_PORT}"
) &
FRONTEND_PID="$!"

echo "[local_dev] starting gateway on ${GATEWAY_HOST}:${GATEWAY_PORT}"
(
  cd "${SERVER_DIR}"
  RAC_GATEWAY_HOST="${GATEWAY_HOST}" \
  RAC_GATEWAY_PORT="${GATEWAY_PORT}" \
  RAC_BACKEND_PORT="${BACKEND_PORT}" \
  RAC_FRONTEND_PORT="${FRONTEND_PORT}" \
  dart run tool/local_gateway.dart
) &
GATEWAY_PID="$!"

echo "[local_dev] app url: http://${GATEWAY_HOST}:${GATEWAY_PORT}"
echo "[local_dev] backend pid=${BACKEND_PID} frontend pid=${FRONTEND_PID} gateway pid=${GATEWAY_PID}"

while true; do
  if ! kill -0 "${BACKEND_PID}" >/dev/null 2>&1; then
    wait "${BACKEND_PID}" || true
    exit 1
  fi
  if ! kill -0 "${FRONTEND_PID}" >/dev/null 2>&1; then
    wait "${FRONTEND_PID}" || true
    exit 1
  fi
  if ! kill -0 "${GATEWAY_PID}" >/dev/null 2>&1; then
    wait "${GATEWAY_PID}" || true
    exit 1
  fi
  sleep 1
done
