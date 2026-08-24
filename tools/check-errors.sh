#!/usr/bin/env bash
# Compiles every error fixture and checks the message a user would read.
#
# Typst has no try/catch, so a unit test cannot assert that a call fails, and an
# example that panicked would fail tools/check.sh. Each fixture under
# tests/errors/ is a snippet that must fail, and declares the phrases its
# message has to carry:
#
#   // expect: outside limits
#
# A fixture passes when the compile exits non-zero and every declared phrase
# appears in the `error:` line. Everything else is a failure: a fixture that
# compiled, one that declares no phrase, and a run that found no fixture at all.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/gribouille-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

fixtures=(tests/errors/*.typ)
total=${#fixtures[@]}

# An empty glob would otherwise report 0/0 and pass, which is what a mistyped
# path looks like.
if [[ ${total} -eq 0 ]]; then
  printf 'errors:   no fixture found under tests/errors/\n' >&2
  exit 1
fi

passed=0

for f in "${fixtures[@]}"; do
  expectations="$(sed -n 's|^// expect: ||p' "${f}")"
  if [[ -z "${expectations}" ]]; then
    printf '  FAIL  %s  declares no "// expect:" phrase\n' "${f}"
    continue
  fi

  # A real .pdf path. `typst compile <file> /dev/null` fails on the output
  # format alone, which would pass the exit-status check below without the
  # library ever running.
  status=0
  out="$(typst compile "${f}" --root "${REPO_ROOT}" \
    "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1)" || status=$?

  if [[ ${status} -eq 0 ]]; then
    printf '  FAIL  %s  compiled; a fixture must fail\n' "${f}"
    continue
  fi

  # The message alone. Typst prints the offending source line and a call trace
  # under it, and both carry code that a phrase could match by accident.
  message="$(printf '%s\n' "${out}" | grep '^error:' || true)"

  missing=0
  while IFS= read -r phrase; do
    [[ -z "${phrase}" ]] && continue
    case "${message}" in
    *"${phrase}"*) ;;
    *)
      printf '  FAIL  %s  message does not carry: %s\n' "${f}" "${phrase}"
      missing=1
      ;;
    esac
  done <<<"${expectations}"

  if [[ ${missing} -ne 0 ]]; then
    printf '        got: %s\n' "${message}"
    continue
  fi

  passed=$((passed + 1))
done

printf '%-9s %d/%d\n' "errors:" "${passed}" "${total}"

if [[ ${passed} -ne ${total} ]]; then
  exit 1
fi
