#!/usr/bin/env bash
# Runs the whole local suite from the project root, the same one CI runs:
# the typstdoc tests and docstring check, the skill inventory, the unit tests,
# the examples and the star history chart, the version check, the visual tests,
# and the error fixtures. Exits non-zero when any of them fails, when a group
# matches no file, or when Lua is not installed.
#
# Flags:
#   --snapshot       Also run the visual snapshot harness in --check mode.
#   --snapshot=ARGS  Pass ARGS through to tools/snapshot/run.lua (e.g. `--only geom-bar`).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/gribouille-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

snapshot_mode=""
snapshot_args=""
for arg in "$@"; do
  case "${arg}" in
  --snapshot) snapshot_mode="check" ;;
  --snapshot=*)
    snapshot_mode="check"
    snapshot_args="${arg#--snapshot=}"
    ;;
  *)
    printf 'unknown arg: %s\n' "${arg}" >&2
    exit 2
    ;;
  esac
done

failures=0
total=0

compile_glob() {
  local label="$1"
  local glob="$2"
  local label_passed=0
  local label_total=0

  for f in ${glob}; do
    label_total=$((label_total + 1))
    total=$((total + 1))
    if typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>/dev/null; then
      label_passed=$((label_passed + 1))
    else
      failures=$((failures + 1))
      printf '  FAIL  %s  %s\n' "${label}" "${f}"
      typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" || true
    fi
  done

  # nullglob is set, so a group that holds nothing would print 0/0 and pass.
  if [[ ${label_total} -eq 0 ]]; then
    printf '%s: nothing matched %s\n' "${label}" "${glob}" >&2
    failures=$((failures + 1))
    return
  fi

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

lua_bin="$(command -v lua5.4 || command -v lua || true)"
if [[ -z "${lua_bin}" ]]; then
  printf 'lua: not installed; the typstdoc and skill inventory checks need Lua 5.4\n' >&2
  failures=$((failures + 1))
else
  "${lua_bin}" tools/typstdoc/test/run.lua || failures=$((failures + 1))
  "${lua_bin}" tools/typstdoc/main.lua --check || failures=$((failures + 1))
  "${lua_bin}" tools/skill-inventory.lua --check || failures=$((failures + 1))
fi

compile_glob "unit" "tests/unit/*.typ"
compile_glob "examples" "examples/*.typ .github/star-history/star-history.typ"

if ! tools/version-check.sh; then
  failures=$((failures + 1))
fi

compile_glob "visual" "tests/visual/*.typ"

# The error fixtures assert the opposite of the globs above: each one must fail,
# with the message it declares. Run unconditionally, because a suite whose whole
# job is to pin a failure must not be skippable.
if ! tools/check-errors.sh; then
  failures=$((failures + 1))
fi

if [[ -n "${snapshot_mode}" ]]; then
  printf '\nsnapshots:\n'
  # shellcheck disable=SC2086  # snapshot_args is intentionally word-split
  if "${lua_bin}" tools/snapshot/run.lua --check ${snapshot_args}; then
    :
  else
    failures=$((failures + 1))
  fi
fi

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${total}"
