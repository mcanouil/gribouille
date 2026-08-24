# Gribouille internal glossary

Canonical expansions for the short identifiers used across `src/`.
Doc-only: this file does not change any name.
It documents the names already in the code.
Run the survey command at the bottom before extending the table.

## Pipeline

| Term      | Expansion                              | Notes                                                                                                                                   |
| --------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `geom`    | geometric layer                        | `geom_*` namespace; layer dict tagged `kind: "layer"`.                                                                                  |
| `aes`     | aesthetic mapping                      | `aes()` constructor; `(channel: column-name-or-marker, ...)`.                                                                           |
| `stat`    | statistical transform                  | `stat_*` namespace; dispatched via `src/stat/apply.typ`.                                                                                |
| `pos`     | position adjustment                    | `position_*` namespace (stack, dodge, fill, jitter, …).                                                                                 |
| `coord`   | coordinate system                      | `coord-*` namespace; `(name: "cartesian"\|"fixed"\|"radial"\|"transform", ...)`.                                                       |
| `spec`    | plot specification dict                | the user-built dict consumed by `render-plot`.                                                                                          |
| `ctx`     | per-draw context                       | dict passed to every geom's `draw(layer, ctx)`. Built once in render/panel-draw.typ (`trained`, `px-range`/`py-range`, `palette`, resolver closures, `theme`, `flipped`, `canvas-w`/`canvas-h`, + `radial` on the geom-dispatch copy).      |
| `mapping` | column-name dict                       | flattened `aes` (`(x: "col", y: "col", colour: "col", ...)`).                                                                           |
| `layer`   | one entry of `spec.layers`             | dict tagged `kind: "layer"` carrying `name` (the geom), `mapping`, `data`, …                                                                       |
| `map`     | mapping (when shortened)               | local variable name; same shape as `mapping`.                                                                                           |
| `params`  | layer-specific parameters              | `layer.params.<channel>` carries pinned values (`stroke`, `colour`, …).                                                                 |
| `draw`    | per-geom render entry point            | every geom exports `draw(layer, ctx)`.                                                                                                  |
| `eval`    | evaluate (closure / late-binding lane) | `eval-after-stat`, `eval-stage`, …                                                                                                      |
| `args`    | arguments                              | Typst `..args` rest binding.                                                                                                            |
| `fun`     | function / closure                     | user-supplied closure passed via `fun:` (`stat-manual`, `stat-summary`).                                                                |
| `defer`   | deferred-panel helper                  | `defer(plot, ...)` / `defer(compose, ...)` partial-applies a renderer into a thunk for `compose`.                                       |
| `as-spec` | spec-return switch                     | internal `plot`/`compose` param. `true` returns the spec dict instead of content. `compose` sets it when materialising a deferred panel. |
| `compose` | multi-plot composition                 | arranges deferred panels and hoists shared legends. See `src/compose.typ`.                                                              |
| `hoist`   | per-aesthetic legend lift              | promote a per-panel guide into the shared legend when every panel agrees on the scale.                                                  |
| `scales`  | keyed-by-aesthetic scale binder        | `scales()` dict fed to `plot()` (`src/scales.typ`). A later entry for an aesthetic wins.                                                |
| `probe`   | first-pass deferred render             | initial `render-plot-deferred` call that reads guides before suppression.                                                               |
| `fail`    | panic helper                           | `src/utils/errors.typ` (`fail`, `fail-enum`, `fail-type`, `fail-range`). Never inline a panic string.                                   |
| `check`   | assert helper                          | `src/utils/errors.typ`; wraps `assert` with the shared message grammar.                                                                 |

## Scale / training

| Term      | Expansion          | Notes                                                            |
| --------- | ------------------ | ---------------------------------------------------------------- |
| `trained` | scale-trained dict | `ctx.trained.<aes>`; carries `type`, `domain`, `level-index`, `spec`, `transform`, `pre-transformed`, `typst-mark`, `integer` (+ optional `temporal`/`date-format`, `reverse`, `view-transform`/`view-index`/`view-pad-cm` added by render/domain.typ). Built by `_train-entry` (scale/train.typ). Read `spec` keys via `spec-attr`. |
| `fwd`     | forward transform  | data → transformed value (`transform-fwd`).                      |
| `inv`     | inverse transform  | transformed value → data (`transform-inv`).                      |
| `sec`     | secondary axis     | `sec-axis()` config bound to the primary scale.                  |
| `ref`     | mapping reference  | `mapping-ref` annotation (e.g., `as-factor()` forced-discrete).  |
| `family`  | scale family       | the scale-stub concept naming one internal builder, stored under the stub's `name:` key. `bind-scale` dispatches on `(aesthetic, name)`. |
| `stub`    | deferred scale spec | `(kind: "scale", name, args)` from a `scale-*` constructor, resolved by `scales()`. |

## Geometry / panel

| Term      | Expansion                 | Notes                                                                                 |
| --------- | ------------------------- | ------------------------------------------------------------------------------------- |
| `cx`      | canvas x                  | post-scale pixel x in the panel coordinate system.                                    |
| `cy`      | canvas y                  | post-scale pixel y in the panel coordinate system.                                    |
| `px`      | panel x                   | panel x range (the `px-range` tuple in `ctx`).                                        |
| `py`      | panel y                   | panel y range.                                                                        |
| `dx`      | delta x                   | local x-offset delta in draw and layout helpers.                                      |
| `dy`      | delta y                   | local y-offset delta in draw and layout helpers.                                      |
| `nudge-x` | x offset                  | aesthetic on `geom-text`/`label`/`typst`. A number means data units (continuous) or level units (discrete). A length means canvas units. |
| `nudge-y` | y offset                  | aesthetic on `geom-text`/`label`/`typst`. A number means data units (continuous) or level units (discrete). A length means canvas units. |
| `aabb`    | axis-aligned bounding box | `(x-lo, y-lo, x-hi, y-hi)` dict from `utils/segment-route.typ`.                       |
| `lo`      | lower bound               | endpoint of an interval (whisker, error bar, axis range).                             |
| `hi`      | upper bound               | endpoint of an interval.                                                              |
| `mid`     | midpoint                  | midpoint of two values (`stat-connect("mid")`, `geom-boxplot`, …).                    |
| `pts`     | points                    | array of `(x, y)` tuples passed to a path/polygon draw.                               |
| `pair`    | adjacent-row tuple        | `(prev, cur)` window over sorted rows.                                                |
| `cap`     | cap length / cap mode     | end-cap of a stroke or arc (radial axis arc).                                         |
| `tick`    | axis tick                 | tick mark (`axis-ticks`, `element-tick`); the label is `axis-text`.                   |
| `ext`     | measured extents          | `(width, height)` cm record from `measure-labels-cm`; an axis title's also carries `along` and `min-width`. |
| `along`   | along-panel reading length | cm an axis title may read before its projection overruns the panel; the box it wraps in (`_title-along-cm`, `_title-boxed`). In `_axes-of` it names the reading axis of a side, paired with `across`. |
| `reach`   | reach from a pin          | cm a label spreads from the point it is anchored at, per canvas side (`_label-reach`). |
| `overhang` | overhang past an edge    | cm a label's reach exceeds its distance from the panel edge; a floor on the chrome margin (`_label-overhang`). |
| `frac`    | fractional position       | a break's place inside the data area, 0 at one end and 1 at the other (`map-break` into `(0, 1)`). |
| `cm`      | centimetres               | Typst length unit; used in numeric helpers (`length-to-cm`).                          |
| `pt`      | points (typographic)      | Typst length unit.                                                                    |

## Data

| Term        | Expansion           | Notes                                                                |
| ----------- | ------------------- | -------------------------------------------------------------------- |
| `row`       | row dictionary      | one element of the data array; user-defined column keys.             |
| `rows`      | row dictionaries    | array of row dictionaries.                                           |
| `col`       | column name         | the string key used to look up a value on a row.                     |
| `cols`      | column names        | array of column-name strings (e.g., group-cols).                     |
| `xs`        | parsed x values     | numeric x array post-`parse-number`.                                 |
| `ys`        | parsed y values     | numeric y array.                                                     |
| `xv` / `yv` | parsed x / y scalar | one parsed numeric value, typically inside a per-row map.            |
| `xn` / `yn` | numeric axis position | one value resolved through `axis-numeric`: a parsed number on a continuous scale, a 1-indexed level on a discrete one. |
| `grp`       | group key           | discrete group identifier (string, joined by `\u{1}` for compounds). |
| `cat`       | category            | discrete level on a categorical scale.                               |
| `num`       | numeric             | parsed scalar.                                                       |
| `idx`       | index               | integer position in an array or palette.                             |
| `len`       | length / count      | array length or numeric count.                                       |
| `key`       | dict key            | bucket key in a partition dict.                                      |
| `raw`       | raw user value      | unparsed cell value before `parse-number`.                           |

## Colour / theme

| Term     | Expansion          | Notes                                                                                                |
| -------- | ------------------ | ---------------------------------------------------------------------------------------------------- |
| `pal`    | palette            | colour palette dict (discrete or continuous).                                                        |
| `ink`    | foreground colour  | theme primary text/line colour (defaults to `black`).                                                |
| `paper`  | background colour  | theme canvas / panel background (defaults to `white`).                                               |
| `accent` | highlight colour   | theme accent (used by some geom defaults).                                                           |
| `tint`   | bar/area body fill | geom fill role: `colour-mix(ink, paper, fill-tint-amount)` (default `0.35`, equivalent to `grey35`). |

## Geometry helpers / misc

| Term      | Expansion                 | Notes                                                                                            |
| --------- | ------------------------- | ------------------------------------------------------------------------------------------------ |
| `band`    | band                      | rectangular shaded region (utils/band.typ).                                                      |
| `gap`     | gap between bins or bars  | x-distance between adjacent bin centres.                                                         |
| `pad`     | padding                   | breathing room (cm) around laid-out content (e.g., strip band text).                             |
| `sub`     | sub-record / sub-element  | nested theme element (e.g., `theme-sub-axis`).                                                   |
| `qq`      | quantile-quantile         | `geom-qq`, `stat-qq`, `stat-qq-line`.                                                            |
| `segment` | connector line            | thin line from a label back to its anchor, opt-in via `segment: true` on text/label/typst geoms. |
| `route`   | routed connector polyline | output of `route-segment`: straight `(p0, p1)` or L-bend `(p0, mid, p1)`, else `none`.           |
| `se`      | standard error            | `mean-se`, `geom-errorbar` summary.                                                              |
| `sp`      | species                   | example data column (penguins / iris-style).                                                     |
| `mm`      | millimetres               | rare; example datasets (penguins flipper length).                                                |
| `cb`      | callback                  | user-supplied closure passed through.                                                            |
| `fn`      | function                  | suffix on a name holding a closure rather than a value (`key-fn`, `to-stat-fn`). Read the value once, then call it many times. |

## Guide layer

| Term      | Expansion           | Notes                                                                                                                                              |
| --------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `entry`   | one guide entry     | one drawn row of a guide: an axis tick, a legend row, a colour-bar tick. `(value, frac, label, tier)`, or `(start, end, label, depth)` for a range. |
| `entries` | guide entry table   | array of `entry` dicts (`src/guide/entry.typ`). Not to be confused with `key`, which keeps the dict-key and legend-glyph senses.                    |
| `tier`    | tick weight         | `"major"` / `"mid"` / `"minor"` on an entry; picks the tick length and whether a label is drawn. Named `tier` because `type` is the trained-scale kind. |
| `depth`   | range nesting level | which row of a bracket stack a range entry occupies; 0 sits nearest the panel.                                                                      |
| `gctx`    | guide context       | what a guide part is drawn under (`src/guide/gctx.typ`): `position`, `aesthetic`, `mode`, `direction`, `axis`, `span`, and the injected `place`, `tick-length`, `key-draw` and `bar-draw` closures. Parallels `ctx`. |
| `mode`    | guide mode          | `"axis"` or `"legend"` on a `gctx`; derived from the aesthetic, and what selects the theme surfaces a part resolves against.                        |
| `across`  | across-guide extent | the thickness axis of a side, growing away from the panel. Paired with `along` in `_axes-of`; the dimension a side reserves.                        |
| `place`   | guide point map     | `(frac, across) -> (x, y)` closure on a `gctx`; the only thing a radial guide changes.                                                              |
| `role`    | theme surface role  | what a part asks a `gctx` for (`"text"`, `"ticks"`, `"line"`, …) instead of naming a surface; resolved by `surface-for`.                            |
| `side-pt` | side-ordered point  | orders an `(along, across)` pair the way a side runs, so one horizontal routine serves all four sides. Named in full because a bare `pt` reads as the Typst length unit. |
| `sweep`   | along-guide angle   | radians a full `frac` covers, on a `gctx` at a position that turns. A part that runs along the guide is a straight segment where it is `none` and a sampled polyline where it is not. |
| `span`    | along-guide length  | cm a full `frac` covers, on a `gctx`. A part that lays its own contents out in centimetres divides by it; a part that runs on fractions never reads it. |
| `metrics` | key cell metrics    | the cm a legend key cell spends (`off`, `drop`, `last`, `line-h`, `slack`, `lead`, `label-lead`, `label-drop`), built by `key-metrics` in `src/guide/grid.typ`. |
| `flow`    | key label flow      | where a label reads against its key: `"right"` beside it, as every vertical legend draws it, or `"below"` under it, as a horizontal size ladder does. |
| `gizmo`   | guide part with a body | a guide part that paints something of its own rather than annotating a span, such as the colour bar in `src/guide/gizmo/`, whose tick flank reads across the guide while the guide stacks down it. |
| `band`    | room past a strip   | on a colour bar, the cm reserved across the guide past the strip, which the tick flank draws into. |
| `band`    | axis band           | on an axis, the cm between the panel edge and whatever sits past it: the ticks, the gap, and the label rows, built by `axis-band` in `src/render/axis-parts.typ` and reserved as `x-edge-band` / `y-edge-band`. |
| `lead`    | room before a label | cm a cell reserves before its label, which the key glyph occupies, or the tick flank on a colour bar. `label-lead` is the shorter offset the drawn label is actually pinned at. |
| `justify` | grid justification  | the alignment a key grid takes inside the guide width, as against `label-align`, which justifies one label inside its own column. |

## Legend placement

| Term        | Expansion               | Notes                                                                                                                       |
| ----------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `placement` | guide placement record  | `(side, align, dx, dy, direction, order, byrow)` attached to every guide; consumed by `legend.draw`.                        |
| `extents`   | per-side legend extents | dict `(top, right, bottom, left, inside)` returned by `legend.estimate-extents`; cm totals plus inside-anchor records.      |
| `side`      | placement side          | `"top"` / `"right"` / `"bottom"` / `"left"` for margin slots, `"inside"` for panel-overlay placement, `"none"` to suppress. |

## Survey

Re-run before extending the table:

```sh
grep -rhoE '\b[a-z]{1,4}\b' src --include='*.typ' \
  | sort | uniq -c | sort -rn | awk '$1 >= 50' | less
```

Filter out Typst keywords (`let`, `if`, `else`, `for`, `at`, `set`, …) and English words.
Anything left at frequency ≥ 50 must be either obviously domain-clear (`data`, `name`, `plot`, `axis`, `bin`, `text`, …) or listed above.
