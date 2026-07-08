# Gribouille architecture

A maintainer-facing map of how the library is wired.
For naming conventions see [`GLOSSARY.md`](GLOSSARY.md); for workflow see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pipeline

Data flows forward only; no stage reaches back into an earlier one.

```text
data ──▶ stat ──▶ position ──▶ scale ──▶ coord ──▶ facet ──▶ theme ──▶ render
```

Entry points trace the same path:

- [`lib.typ`](lib.typ) is the public facade.
  It re-exports every user-facing function (`plot`, `aes`, `annotate`, `geom-*`, `stat-*`, `scale-*`, `scales`, `theme-*`, `labels`, `guides`, `compose`, …).
  Internal helpers stay unexported and are `_`-prefixed.
- [`src/plot.typ`](src/plot.typ) is the grammar entry point.
  It normalises data, flattens the aesthetic mapping, merges per-layer mappings, and builds the spec dict.
- [`src/render.typ`](src/render.typ) orchestrates rendering.
  It trains scales, applies stats/positions/coord/facet/theme/labels, then dispatches to the canvas builders under [`src/render/`](src/render).

## Module map

| Directory | Purpose |
| --- | --- |
| `src/geom/` | Geometric layers; each exports a constructor (via `make-layer`) and a `draw(layer, ctx)`. Shared draw scaffolding for geom families (`grouped-path`, `errorbar-draw`, `ref-line`, `label-draw`) lives here too. |
| `src/stat/` | Statistical transforms; dispatched by `src/stat/apply.typ`. |
| `src/position/` | Position adjustments (stack, dodge, fill, jitter, …); dispatched by `src/position/apply.typ`. |
| `src/scale/` | Aesthetic-agnostic scales: `constructors.typ` returns family-tagged stubs, `bind.typ` dispatches `(aesthetic, name)` to family-file builders (continuous, discrete, colour, date, size, …), `train.typ` trains domains. |
| `src/coord/` | Coordinate systems (cartesian, fixed, flip, radial, transform). |
| `src/facet/` | Faceting (grid, wrap) and strip labellers. |
| `src/guide/` | Legend and axis configuration plus legend-symbol drawing. |
| `src/theme/` | Theme structure, named themes, element builders, global state. |
| `src/render/` | Rendering pipeline: domain, facet layout, panel draw, canvas, chrome, legend renderer (`render/legend.typ`). |
| `src/utils/` | Shared leaf helpers: types, formatting, colour, late-binding, binning, errors. No cetz drawing lives here. |
| `src/datasets/` | Built-in example datasets (economics, mpg, penguins). |

Design tenets worth knowing before editing:

- **Spec dict as the intermediate form.** `plot()` returns a spec so `compose()` can defer rendering and hoist shared legends across panels.
- **Late binding.** Aesthetic values can resolve at later stages (`after-stat`, `after-scale`, `from-theme`, `stage`); see [`src/utils/late-binding.typ`](src/utils/late-binding.typ).
- **Per-facet stat re-training.** Stats such as smooth, bin, and boxplot re-run per panel to respect facet semantics.
- **Single CeTZ import.** Only [`src/deps.typ`](src/deps.typ) imports third-party packages; `tools/typstdoc` rejects `@preview/*` imports elsewhere under `src/`.
- **Keyed-by-aesthetic plot inputs.** `scales()` ([`src/scales.typ`](src/scales.typ)), `guides()` ([`src/guides.typ`](src/guides.typ)), and `labels()` ([`src/labels.typ`](src/labels.typ)) each build a dict keyed by aesthetic and feed it to `plot()`; a later entry for the same aesthetic wins. `expand-limits` ([`src/limits.typ`](src/limits.typ)) and `annotate` ([`src/annotate.typ`](src/annotate.typ)) are top-level shortcuts, and [`src/aes-keys.typ`](src/aes-keys.typ) single-sources the `AES-KEYS` channel list.

## Adding things

- **A geom.** Copy the closest existing `src/geom/*.typ`, build the layer with `make-layer` from [`src/layer.typ`](src/layer.typ), and export the constructor through [`lib.typ`](lib.typ).
  Provide a legend symbol via `src/guide/draw-key.typ` / `src/guide/draw-marker.typ`.
- **A stat.** Add `src/stat/<name>.typ` and register it in [`src/stat/apply.typ`](src/stat/apply.typ).
- **A position.** Add `src/position/<name>.typ` and register it in [`src/position/apply.typ`](src/position/apply.typ).
- **A scale.** Add or extend the internal builder in the relevant family file (`src/scale/continuous.typ`, `src/scale/colour.typ`, …), register its family name under each supported aesthetic in the [`src/scale/bind.typ`](src/scale/bind.typ) dispatch table, expose a public `scale-<name>` constructor in [`src/scale/constructors.typ`](src/scale/constructors.typ) (returns `_stub(family, args)`), and re-export it through [`lib.typ`](lib.typ).

## Error conventions

Never inline a panic string.
Route every validation through [`src/utils/errors.typ`](src/utils/errors.typ), which centralises the grammar:

```text
<scope>: <problem>; got <repr(value)>. <hint>
```

- `fail(scope, problem, hint: none)` for bespoke messages.
- `fail-enum(scope, name, value, valid, hint: none)` for "must be one of …".
- `fail-type(scope, name, value, expected, hint: none)` for type mismatches.
- `fail-range(scope, name, value, lo, hi, lo-open: …, hi-open: …, hint: none)` for numeric intervals.
- `check(cond, scope, problem, hint: none)` replaces a bare `assert`.

Typst cannot catch a panic, so the message *builders* (`error-text`, `enum-text`, `type-text`, `range-text`) are pure and unit-tested in [`tests/unit/test-errors.typ`](tests/unit/test-errors.typ).

## Testing and naming

- [`tests/unit/`](tests/unit) holds pure-function assertions compiled by `typst compile`; add unit tests here for any new helper.
- [`tests/visual/`](tests/visual) holds PNG snapshot goldens checked via `tools/snapshot/run.lua`.
  Goldens are CPU-architecture sensitive; refresh them through the Linux snapshot workflow, not locally.
- Run [`tools/check.sh`](tools/check.sh) to mirror CI (compiles every unit test and example; `--snapshot` adds the visual check).
- Consult [`GLOSSARY.md`](GLOSSARY.md) before introducing any new short identifier.
