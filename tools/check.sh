#!/usr/bin/env bash
# Compiles every Typst example and unit test from the project root.
# Mirrors the .github/actions/typst-compile composite action so local runs
# match CI exactly. Exits non-zero on the first failure across all targets.
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
  shift 2
  local label_passed=0
  local label_total=0

  for f in ${glob}; do
    label_total=$((label_total + 1))
    total=$((total + 1))
    if typst compile "${f}" --root "${REPO_ROOT}" "$@" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>/dev/null; then
      label_passed=$((label_passed + 1))
    else
      failures=$((failures + 1))
      printf '  FAIL  %s  %s\n' "${label}" "${f}"
      typst compile "${f}" --root "${REPO_ROOT}" "$@" "${OUT_DIR}/$(basename "${f%.typ}").pdf" || true
    fi
  done

  printf '%-14s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

if command -v lua5.4 >/dev/null 2>&1; then
  lua5.4 tools/typstdoc/test/run.lua
  lua5.4 tools/skill-inventory.lua --check
elif command -v lua >/dev/null 2>&1; then
  lua tools/typstdoc/test/run.lua
  lua tools/skill-inventory.lua --check
else
  printf 'typstdoc tests: SKIP (lua not installed)\n'
  printf 'skill inventory: SKIP (lua not installed)\n'
fi

if ! tools/package-path.sh --self-test; then
  failures=$((failures + 1))
fi
PACKAGE_PATH="$(tools/package-path.sh "${OUT_DIR}/packages")"

compile_glob "unit"     "tests/unit/*.typ"
compile_glob "examples" "examples/*.typ" --package-path "${PACKAGE_PATH}"
compile_glob "star-history" ".github/star-history/star-history.typ" --package-path "${PACKAGE_PATH}"

# The examples and the star history chart show the import a reader copies, so
# each must name the version typst.toml publishes. release.yml bumps them.
check_import_versions() {
  local version file found checked=0
  local bad=()
  version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
  for file in examples/*.typ .github/star-history/star-history.typ; do
    checked=$((checked + 1))
    if ! grep -qE '^#import "@preview/gribouille:[0-9]+\.[0-9]+\.[0-9]+"' "${file}"; then
      bad+=("${file}: no #import \"@preview/gribouille:${version}\" line; add one in place of any lib.typ import")
      continue
    fi
    while IFS= read -r found; do
      if [[ "${found}" != "${version}" ]]; then
        bad+=("${file}: imports ${found}; typst.toml has ${version}")
      fi
    done < <(grep -oE '@preview/gribouille:[0-9]+\.[0-9]+\.[0-9]+' "${file}" | cut -d: -f2)
  done
  if [[ ${#bad[@]} -gt 0 ]]; then
    failures=$((failures + 1))
    printf '  FAIL  imports  %s\n' "${bad[@]}"
  fi
  printf '%-14s %d/%d\n' "imports:" "$((checked - ${#bad[@]}))" "${checked}"
}
check_import_versions
compile_glob "visual"   "tests/visual/*.typ"

# The error fixtures assert the opposite of the globs above: each one must fail,
# with the message it declares. Run unconditionally, because a suite whose whole
# job is to pin a failure must not be skippable.
if ! tools/check-errors.sh; then
  failures=$((failures + 1))
fi

if [[ -n "${snapshot_mode}" ]]; then
  printf '\nsnapshots:\n'
  # shellcheck disable=SC2086  # snapshot_args is intentionally word-split
  if lua tools/snapshot/run.lua --check ${snapshot_args}; then
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
