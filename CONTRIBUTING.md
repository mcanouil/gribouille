# Contributing to Gribouille

Thanks for your interest in helping improve Gribouille.
This document explains where to file what, what to include in a bug report, and the basics of working on the source.

## Where to file what

Pick the right channel before opening anything:

- **Bug report.**
  Use [Issues → Bug report](https://github.com/mcanouil/gribouille/issues/new?template=bug.yml) only for confirmed defects with a reproducible example.
- **Feature request or idea.**
  Open a thread in [Discussions → Ideas](https://github.com/mcanouil/gribouille/discussions/new?category=ideas).
  Feature requests opened as issues will be redirected.
- **Question or help.**
  Open a thread in [Discussions → Q&A](https://github.com/mcanouil/gribouille/discussions/new?category=q-a).
- **Existing thread.**
  Browse [Discussions](https://github.com/mcanouil/gribouille/discussions) before creating a new one and comment on the relevant thread when it exists.

## Reporting a bug

Before submitting a bug, please confirm all of the following:

1. You have searched the [issue tracker](https://github.com/mcanouil/gribouille/issues?q=is%3Aissue) and could not find a similar report.
2. You have updated to the latest released version of Gribouille and reproduced the bug on that version.
3. You are reporting a bug, not requesting a feature or asking a question.

Every bug report should include:

- The Gribouille version and the Typst compiler version (`typst --version`).
- A minimal reproducible Typst document that imports Gribouille via `#import "@preview/gribouille:<version>": *`.
- Numbered steps to reproduce.
- The expected behaviour and the actual behaviour, with any error output pasted verbatim inside a fenced code block.

## Accessibility

Please keep contributed content accessible:

- Add descriptive alt text to every image, screenshot, or diagram you attach (`![alt text describing the image](url)`).
- Do not rely on colour alone to convey meaning in screenshots, examples, or chart output.
- Quote error output as text inside fenced code blocks rather than pasting it as an image.

## Development setup

The package metadata, compiler version, and excluded paths are defined in [`typst.toml`](typst.toml).
The library entry point is [`lib.typ`](lib.typ).
Source modules live under [`src/`](src/).
Tests live under [`tests/unit/`](tests/unit) and [`tests/visual/`](tests/visual).
Helper scripts live under [`tools/`](tools), in particular [`tools/check.sh`](tools/check.sh) for local checks.
Short identifiers used across the source tree (`ctx`, `spec`, `mapping`, `cx`, `cy`, `lo`, `hi`, …) are catalogued in [`GLOSSARY.md`](GLOSSARY.md).
Please consult that glossary before introducing new short identifiers.
[`ARCHITECTURE.md`](ARCHITECTURE.md) maps the rendering pipeline, module boundaries, and where to add a geom, stat, scale, or position.

### Documenting unreleased API

The documentation site renders its pages from `main`, but pins `src/` and `lib.typ` to the latest release tag, so that the stable site documents the version people can actually install.
A page calling API that is newer than the latest release therefore cannot compile, and fails the release build.

When a page documents API that has not shipped yet, declare it in the frontmatter, matching the newest `@since` the page calls:

```yaml
---
title: "Wrangling data"
since: "0.6.0"
---
```

The stable site then renders a short pointer to the development documentation in place of the page, and the development site renders it in full.
The tag stays harmless once that version ships, so there is nothing to remove later.

Verify with `lua tools/docs-since.lua --check`, which [`tools/check.sh`](tools/check.sh) runs for you.

### Error messages

Never inline a panic string.
Route every validation through [`src/utils/errors.typ`](src/utils/errors.typ) (`fail`, `fail-enum`, `fail-type`, `fail-range`, `check`), which enforces the message grammar `<scope>: <problem>; got <repr(value)>. <hint>`.

## Commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/) prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `style:`, `test:`, `ci:`).
Keep the subject line concise (ideally under 50 characters) and skip the body and footer unless absolutely needed.
