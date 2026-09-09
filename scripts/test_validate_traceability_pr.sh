#!/usr/bin/env bash
set -euo pipefail

validator="scripts/validate_traceability_pr.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

cat > "${tmpdir}/valid.md" <<'EOF'
# Pull Request

Trace ID: TRACE-SETUP-01
Baseline reference: Master Plan v1.0 §17

- [x] `implements`
EOF

"${validator}" "${tmpdir}/valid.md"

cat > "${tmpdir}/missing-trace.md" <<'EOF'
# Pull Request

Baseline reference: Master Plan v1.0 §17

- [x] `implements`
EOF

if "${validator}" "${tmpdir}/missing-trace.md"; then
  echo "Expected missing Trace ID validation to fail." >&2
  exit 1
fi

cat > "${tmpdir}/missing-baseline.md" <<'EOF'
# Pull Request

Trace ID: TRACE-SETUP-01

- [x] `implements`
EOF

if "${validator}" "${tmpdir}/missing-baseline.md"; then
  echo "Expected missing baseline reference validation to fail." >&2
  exit 1
fi

cat > "${tmpdir}/missing-classification.md" <<'EOF'
# Pull Request

Trace ID: TRACE-SETUP-01
Baseline reference: Master Plan v1.0 §17
EOF

if "${validator}" "${tmpdir}/missing-classification.md"; then
  echo "Expected missing classification validation to fail." >&2
  exit 1
fi

echo "Traceability validator tests passed."
