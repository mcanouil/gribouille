# `.github/scripts`

Maintainer scripts run from a developer machine, not from CI.

## `publish-typst-universe.sh`

Submits a published gribouille release to [Typst Universe](https://typst.app/universe) by opening a fork-to-upstream pull request on [`typst/packages`](https://github.com/typst/packages).

It authenticates with the maintainer's own `gh` session because opening that PR needs a real user identity (a GitHub App token cannot open it), so it is the canonical submitter and is run by hand after each release.

### What it does

1. Resolves the release tag (argument or latest) and verifies the release and its `gribouille-<version>.tar.gz` asset exist.
2. Downloads that exact release asset so the Universe payload is byte-identical with what users download.
3. Clones the fork of `typst/packages` (blobless, sparse: only `packages/preview/gribouille` is checked out).
4. Rebuilds the submission branch from a clean `upstream/main`, copies the payload to `packages/preview/gribouille/<version>`, and commits.
5. Pushes the branch to the fork and opens, reuses, or retargets the upstream PR.

### Usage

```sh
.github/scripts/publish-typst-universe.sh [--dry-run] [--pr=NUM] [VERSION]
```

| Argument    | Meaning                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `VERSION`   | Release tag to submit (e.g. `0.4.1`). Blank uses the latest release.                                                             |
| `--dry-run` | Download the asset, clone, and branch locally, but skip the push and the PR. Still requires the release and its asset to exist.  |
| `--pr=NUM`  | Retarget an existing open submission PR (`typst/packages` #`NUM`) to `VERSION` instead of opening a new one.                     |

### `--pr=NUM`: bumping an open submission

Each version normally lands on its own branch (`gribouille-<version>`) and its own PR.
When an earlier submission PR is still open and unmerged, `--pr=NUM` reuses that PR's head branch and edits the PR in place: the branch is rebuilt from clean `upstream/main` so only the new version's directory remains, then force-pushed, and the PR title and body are updated.

The branch keeps its original name even though it now carries the newer version; this is required to keep the same PR.
The script verifies the PR is open and that its head branch belongs to the configured fork before touching anything.

```sh
# Replace the open gribouille:0.4.0 submission (PR #5132) with 0.4.1.
.github/scripts/publish-typst-universe.sh --pr=5132 0.4.1
```

### Requirements

- `gh`, `git`, and `tar` on `PATH`.
- An authenticated `gh` session (`gh auth login`).

### Environment

| Variable                | Default                              | Meaning                          |
| ----------------------- | ------------------------------------ | -------------------------------- |
| `TYPST_PACKAGES_FORK`   | `mcanouil/typst-universe-packages`   | Fork of `typst/packages` to use. |
