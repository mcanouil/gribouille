#!/usr/bin/env bash
# Holds the import that the examples and the star history chart show to the
# version typst.toml publishes.
#
# A reader copies that import line, so each file must carry
# `#import "@preview/gribouille:<version>"` with the manifest's version.
# release.yml bumps them with typst.toml. Run by tools/check.sh and checks.yml.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
files=(examples/*.typ .github/star-history/star-history.typ)
bad=()
for file in "${files[@]}"; do
  found="$(grep -oE '^#import "@preview/gribouille:[0-9]+\.[0-9]+\.[0-9]+"' "${file}" | cut -d: -f2 | tr -d '"' || true)"
  if [[ -z "${found}" ]]; then
    bad+=("${file}: no #import \"@preview/gribouille:${version}\" line; add one in place of any lib.typ import")
  elif [[ "${found}" != "${version}" ]]; then
    bad+=("${file}: imports ${found//$'\n'/, }; typst.toml has ${version}")
  fi
done

if [[ ${#bad[@]} -gt 0 ]]; then
  printf '  FAIL  imports  %s\n' "${bad[@]}"
fi
printf '%-9s %d/%d\n' "imports:" "$((${#files[@]} - ${#bad[@]}))" "${#files[@]}"
[[ ${#bad[@]} -eq 0 ]]
