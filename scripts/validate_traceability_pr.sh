#!/usr/bin/env bash
set -euo pipefail

PR_BODY_FILE="${1:-}"

if [[ -z "${PR_BODY_FILE}" || ! -f "${PR_BODY_FILE}" ]]; then
  echo "Usage: $0 <pull-request-body-file>" >&2
  exit 2
fi

body="$(cat "${PR_BODY_FILE}")"

if ! grep -Eq 'Trace ID:[[:space:]]*[^<[:space:]][^[:cntrl:]]*' <<< "${body}"; then
  echo "Traceability validation failed: PR body must include a non-empty 'Trace ID:' field." >&2
  exit 1
fi

if ! grep -Eq 'Baseline reference:[[:space:]]*[^<[:space:]][^[:cntrl:]]*' <<< "${body}"; then
  echo "Traceability validation failed: PR body must include a non-empty 'Baseline reference:' field." >&2
  exit 1
fi

if ! grep -Eq '`(implements|test-only|refactor-no-contract-change|requires-change-control)`' <<< "${body}"; then
  echo "Traceability validation failed: PR body must select a valid change classification." >&2
  exit 1
fi

echo "Traceability validation passed."
