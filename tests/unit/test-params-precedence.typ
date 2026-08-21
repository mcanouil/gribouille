// Verify the precedence rule for layer parameters across aesthetics:
// a pinned `params.<aes>` wins over the trained scale, and the mapping only
// takes effect when the param is left at `auto` (or `none` for colour).
//
// The resolvers take the parameters rather than the layer they came off,
// because they run once a row and a layer reaches every row of the plot.

#import "../../src/utils/colour-resolve.typ": (
  resolve-alpha, resolve-linewidth, resolve-size,
)

#let alpha-trained = (
  type: "continuous",
  domain: (0, 10),
  spec: (range: (0.1, 1)),
)

// 1. Mapped alpha wins when `params.alpha` is `auto`: a row at the upper end
// of the domain resolves to the spec range maximum.
#let ctx-alpha = (trained: (alpha: alpha-trained))
#assert.eq(
  resolve-alpha(
    (alpha: auto),
    (alpha: "k"),
    ctx-alpha,
    (k: 10),
  ),
  1,
)

// 2. Pinned numeric `params.alpha` overrides the mapped scale: the pinned
// value wins regardless of the row's mapped column.
#assert.eq(
  resolve-alpha(
    (alpha: 0.25),
    (alpha: "k"),
    ctx-alpha,
    (k: 10),
  ),
  0.25,
)

// 3. `default-alpha` is the fallback when neither pin nor mapping applies.
#assert.eq(
  resolve-alpha(
    (alpha: auto),
    (:),
    (trained: (:)),
    (:),
    default-alpha: 0.4,
  ),
  0.4,
)

#let lw-trained = (
  type: "continuous",
  domain: (0, 10),
  spec: (range: (0.4pt, 2pt)),
)

// 4. Mapped linewidth wins when `params.linewidth` is `auto`.
#let ctx-lw = (trained: (linewidth: lw-trained))
#assert.eq(
  resolve-linewidth(
    (linewidth: auto, stroke: 0.8pt),
    (linewidth: "k"),
    ctx-lw,
    (k: 0),
    0.8pt,
  ),
  0.4pt,
)

// 5. Pinned `params.linewidth` length overrides the mapped scale.
#assert.eq(
  resolve-linewidth(
    (linewidth: 1.6pt, stroke: 0.8pt),
    (linewidth: "k"),
    ctx-lw,
    (k: 10),
    0.8pt,
  ),
  1.6pt,
)

#let size-trained = (
  type: "continuous",
  domain: (0, 10),
  spec: (range: (1pt, 6pt)),
)

// 6. Mapped size wins when `params.size` is `auto`.
#let ctx-size = (trained: (size: size-trained))
#assert.eq(
  resolve-size(
    (size: auto),
    (size: "k"),
    ctx-size,
    (k: 10),
    1.5pt,
  ),
  6pt,
)

// 7. Pinned `params.size` length overrides the mapped scale.
#assert.eq(
  resolve-size(
    (size: 4pt),
    (size: "k"),
    ctx-size,
    (k: 10),
    1.5pt,
  ),
  4pt,
)

// 8. `default-size` is the fallback when neither pin nor mapping applies.
#assert.eq(
  resolve-size(
    (size: auto),
    (:),
    (trained: (:)),
    (:),
    1.5pt,
  ),
  1.5pt,
)

Layer parameter precedence tests passed.
