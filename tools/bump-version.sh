#!/usr/bin/env bash
# Writes the next version into every file that holds it, then holds them to one
# another with tools/version-check.sh. The Release workflow runs it, and so can
# anyone, since it changes files and nothing else.
#
# Usage:
#   bump-version.sh <patch|minor|major>
#   bump-version.sh --self-test
#
# The version is read from typst.toml. The files are:
#
#   - typst.toml, the version Typst Universe publishes;
#   - CITATION.cff, its version and the date it was released;
#   - CHANGELOG.md, whose `## Unreleased` heading becomes `## X.Y.Z (date)`;
#   - README.md and skills/gribouille/SKILL.md, the imports a reader copies;
#   - .claude-plugin/plugin.json, the plugin version.
#
# tools/version-check.sh refuses a versioned import in any other file, so no
# file can join the list without that check saying so.
#
# Prints the new version on stdout, and nothing else.
# RELEASE_DATE overrides today's date, in UTC, as YYYY-MM-DD.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

next_version() {
  local current="$1" part="$2"
  local major minor patch
  if [[ ! "${current}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    printf 'bump-version: typst.toml names no semantic version; got "%s". Set version = "x.y.z".\n' "${current}" >&2
    return 1
  fi
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
  case "${part}" in
  major) printf '%d.0.0\n' "$((major + 1))" ;;
  minor) printf '%d.%d.0\n' "${major}" "$((minor + 1))" ;;
  patch) printf '%d.%d.%d\n' "${major}" "${minor}" "$((patch + 1))" ;;
  *)
    printf 'bump-version: the part to bump is patch, minor or major; got "%s".\n' "${part}" >&2
    return 1
    ;;
  esac
}

# The changelog must hold an Unreleased section with an entry in it: a release
# with nothing under its heading publishes empty notes.
unreleased_entries() {
  awk '
    /^## Unreleased$/ { inside = 1; found = 1; next }
    /^## / { inside = 0 }
    inside && /^- / { entries += 1 }
    END { if (!found) exit 2; print entries + 0 }
  ' "$1"
}

rewrite_files() {
  local dir="$1" version="$2" date="$3"
  local entries
  entries="$(unreleased_entries "${dir}/CHANGELOG.md")" || {
    printf 'bump-version: CHANGELOG.md has no "## Unreleased" heading. Add one above the last release.\n' >&2
    return 1
  }
  if [[ "${entries}" -eq 0 ]]; then
    printf 'bump-version: "## Unreleased" in CHANGELOG.md holds no entry. Record the changes first.\n' >&2
    return 1
  fi

  # perl rather than sed: `sed -i` takes a different argument on macOS and on
  # Linux, and perl edits in place on both with no backup file left behind.
  export VERSION="${version}" DATE="${date}"
  perl -pi -e 's/^(version\s*=\s*")[^"]+/$1$ENV{VERSION}/' "${dir}/typst.toml"
  perl -pi -e 's/^## Unreleased$/## $ENV{VERSION} ($ENV{DATE})/' "${dir}/CHANGELOG.md"
  perl -pi -e 's/(\@preview\/gribouille:)\d+\.\d+\.\d+/$1$ENV{VERSION}/g' \
    "${dir}/README.md" "${dir}/skills/gribouille/SKILL.md"
  perl -pi -e 's/^(\s*"version"\s*:\s*")[^"]+/$1$ENV{VERSION}/' "${dir}/.claude-plugin/plugin.json"
  # The date line is replaced where it is, or added after the version when the
  # citation has none yet.
  perl -0pi -e '
    s/^version:.*$/version: $ENV{VERSION}/m;
    s/^date-released\s*:.*$/date-released: "$ENV{DATE}"/m
      or s/^(version:.*)$/$1\ndate-released: "$ENV{DATE}"/m;
  ' "${dir}/CITATION.cff"
}

if [[ "${1:-}" == "--self-test" ]]; then
  fixtures="$(mktemp -d)"
  trap 'rm -rf "${fixtures}"' EXIT
  cases=0
  bad=0

  versioned() {
    local current="$1" part="$2" wanted="$3"
    cases=$((cases + 1))
    local got
    got="$(next_version "${current}" "${part}" 2>/dev/null)" || got="<refused>"
    if [[ "${got}" != "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s %s  wanted %s, got %s\n' "${part}" "${current}" "${wanted}" "${got}" >&2
    fi
  }

  versioned 0.7.0 minor 0.8.0
  versioned 0.7.0 patch 0.7.1
  versioned 0.9.3 major 1.0.0
  versioned 0.7 minor '<refused>'
  versioned 0.7.0 build '<refused>'

  # The import is built from a variable, as in version-check.sh, so the scan of
  # tracked files does not read a fixture as a hard-coded version.
  mark='@preview/gribouille'
  write_fixtures() {
    mkdir -p "${fixtures}/skills/gribouille" "${fixtures}/.claude-plugin"
    printf '[package]\nname = "gribouille"\nversion = "0.7.0"\ncompiler = "0.15.0"\n' >"${fixtures}/typst.toml"
    printf 'title: "Gribouille"\ndate-released: "2026-08-24"\nversion: 0.7.0\n' >"${fixtures}/CITATION.cff"
    printf '# Changelog\n\n## Unreleased\n\n### Breaking changes\n\n- feat!: A change.\n\n## 0.7.0 (2026-08-24)\n\n- feat: Before.\n' >"${fixtures}/CHANGELOG.md"
    printf '#import "%s:0.7.0": *\n' "${mark}" >"${fixtures}/README.md"
    printf '#import "%s:0.7.0": *\n\nSee %s:0.7.0.\n' "${mark}" "${mark}" >"${fixtures}/skills/gribouille/SKILL.md"
    printf '{\n  "name": "gribouille",\n  "version": "0.7.0"\n}\n' >"${fixtures}/.claude-plugin/plugin.json"
  }

  holds() {
    local file="$1" line="$2" label="$3"
    cases=$((cases + 1))
    if ! grep -qxF -- "${line}" "${fixtures}/${file}"; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted %s to hold: %s\n' "${label}" "${file}" "${line}" >&2
      sed 's/^/        /' "${fixtures}/${file}" >&2
    fi
  }

  write_fixtures
  rewrite_files "${fixtures}" 0.8.0 2026-10-15
  holds typst.toml 'version = "0.8.0"' 'the manifest'
  holds typst.toml 'compiler = "0.15.0"' 'the compiler left alone'
  holds CITATION.cff 'version: 0.8.0' 'the citation version'
  holds CITATION.cff 'date-released: "2026-10-15"' 'the citation date, in place'
  holds CHANGELOG.md '## 0.8.0 (2026-10-15)' 'the changelog heading'
  holds CHANGELOG.md '## 0.7.0 (2026-08-24)' 'the last release left alone'
  holds README.md "#import \"${mark}:0.8.0\": *" 'the README import'
  holds skills/gribouille/SKILL.md "#import \"${mark}:0.8.0\": *" 'the skill import'
  holds skills/gribouille/SKILL.md "See ${mark}:0.8.0." 'the second skill mention'
  holds .claude-plugin/plugin.json '  "version": "0.8.0"' 'the plugin version'
  holds .claude-plugin/plugin.json '  "name": "gribouille",' 'the plugin name left alone'

  cases=$((cases + 1))
  if rewrite_files "${fixtures}" 0.9.0 2026-11-01 2>/dev/null; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  a changelog with no Unreleased section was bumped\n' >&2
  fi

  cases=$((cases + 1))
  printf '# Changelog\n\n## Unreleased\n\n## 0.8.0 (2026-10-15)\n\n- feat: Before.\n' >"${fixtures}/CHANGELOG.md"
  if rewrite_files "${fixtures}" 0.9.0 2026-11-01 2>/dev/null; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  an empty Unreleased section was bumped\n' >&2
  fi

  if [[ ${bad} -gt 0 ]]; then
    printf 'bump-version: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi
  printf 'bump:     self-test %d/%d\n' "${cases}" "${cases}" >&2
  exit 0
fi

if [[ $# -ne 1 ]]; then
  printf 'bump-version: expected one argument; got %d. Run tools/bump-version.sh <patch|minor|major>.\n' "$#" >&2
  exit 1
fi

cd "${REPO_ROOT}"
current="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
version="$(next_version "${current}" "$1")"
date="${RELEASE_DATE:-$(date -u +%Y-%m-%d)}"
if [[ ! "${date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  printf 'bump-version: RELEASE_DATE is not YYYY-MM-DD; got "%s".\n' "${date}" >&2
  exit 1
fi

rewrite_files "${REPO_ROOT}" "${version}" "${date}"
tools/version-check.sh >&2
printf '%s\n' "${version}"
