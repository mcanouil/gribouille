# Contributing to Gribouille

Thanks for your interest in helping improve Gribouille.
This document explains where to file what, what to include in a bug report, and the basics of working on the source.

## Where to file what

Pick the right channel before opening anything:

- **Bug report.**
  Use [Issues → Bug report](https://github.com/mcanouil/gribouille/issues/new?template=bug.yml) only for confirmed defects with a reproducible example.
- **Feature request or idea.**
  Open a thread in [Discussions → Ideas](https://github.com/mcanouil/gribouille/discussions/new?category=ideas).
  I redirect feature requests opened as issues.
- **Question or help.**
  Open a thread in [Discussions → Q&A](https://github.com/mcanouil/gribouille/discussions/new?category=q-a).
- **Existing thread.**
  Browse [Discussions](https://github.com/mcanouil/gribouille/discussions) before you create a new one.
  If a relevant thread exists, comment on it.

## Reporting a bug

Before submitting a bug, confirm all of the following:

1. You have searched the [issue tracker](https://github.com/mcanouil/gribouille/issues?q=is%3Aissue) and could not find a similar report.
2. You have updated to the latest released version of Gribouille and reproduced the bug on that version.
3. You are reporting a bug, not requesting a feature or asking a question.

Every bug report must include:

- The Gribouille version and the Typst compiler version (`typst --version`).
- A minimal reproducible Typst document that imports Gribouille via `#import "@preview/gribouille:<version>": *`.
- Numbered steps to reproduce.
- The expected behaviour and the actual behaviour, with any error output pasted verbatim inside a fenced code block.

## Accessibility

Keep contributed content accessible:

- Add descriptive alt text to every image, screenshot, or diagram you attach (`![alt text describing the image](url)`).
- Do not rely on colour alone to convey meaning in screenshots, examples, or chart output.
- Quote error output as text inside fenced code blocks rather than pasting it as an image.

## Development setup

The package metadata, compiler version, and excluded paths are defined in [`typst.toml`](typst.toml).
The library entry point is [`lib.typ`](lib.typ).
Source modules live under [`src/`](src/).
Tests live under [`tests/unit/`](tests/unit), [`tests/visual/`](tests/visual), and [`tests/errors/`](tests/errors).
Every file under `tests/errors/` must fail to compile, and declares the phrases its message has to carry on `// expect:` lines, because Typst has no `try`/`catch` for a unit test to use.
Helper scripts live under [`tools/`](tools), in particular [`tools/check.sh`](tools/check.sh) for local checks.
Short identifiers used across the source tree (`ctx`, `spec`, `mapping`, `cx`, `cy`, `lo`, `hi`, …) are catalogued in [`GLOSSARY.md`](GLOSSARY.md).
Consult that glossary before you introduce new short identifiers.
[`ARCHITECTURE.md`](ARCHITECTURE.md) maps the rendering pipeline, module boundaries, and where to add a geom, stat, scale, or position.

### Visual snapshots

Figures under [`tests/visual/golden/`](tests/visual/golden) are minted by CI and never committed from a working copy.
Install the compiler [`typst.toml`](typst.toml) pins before you read a snapshot result, because a different Typst release renders the same source differently and reports diffs that have nothing to do with your change.

Run `lua tools/snapshot/run.lua --check` locally to see which snapshots your change moves.
When a change is meant to move them, dispatch the `Refresh visual snapshots` workflow on your branch and let CI write the goldens:

```sh
gh workflow run snapshot-refresh.yml --ref <branch> -f direct=true
```

The harness refuses `--update` outside CI, so there is nothing to remember beyond running the workflow.

### Documenting unreleased API

The project publishes two sites.
The stable site is at the site root and renders wholly from the latest release tag.
The development site is at `/dev/` and renders from `main`.
Each is built from a single ref, so a page always documents the API of the version it ships with.

Write documentation against `main` as you would any other change.
A page that describes unreleased API reaches the development site on merge.
It reaches the stable site when the next release is tagged.
Renames and removals need no special handling, since the stable site never renders `main`'s prose.

In return, a documentation fix reaches the stable site only at the next release.

### Error messages

Never inline a panic string.
Route every validation through [`src/utils/errors.typ`](src/utils/errors.typ) (`fail`, `fail-enum`, `fail-type`, `fail-range`, `check`), which enforces the message grammar `<scope>: <problem>; got <repr(value)>. <hint>`.

## Commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/) prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `style:`, `test:`, `ci:`).
Keep the subject line concise (ideally under 50 characters).
Skip the body and footer unless they are necessary.
