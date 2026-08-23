// The bin grid resolvers are lazy: a stashed panel-wide grid is answered
// without asking the caller for its values.
//
// `params.grid` is set once per panel by `panel-bin-grid`, so every per-group
// `apply()` call after that already has its partition. Building the value
// arrays for a resolver that will not look at them costs one full pass per
// group, which is why the resolvers take thunks rather than arrays.
//
// The last case pins that `bin-1d-cells` honours the stashed grid. Laziness
// itself stays unpinned: an eager `entries.map()` inside the thunk has no
// observable effect, and Typst offers no cheap way to instrument the read. A
// revert of the thunk at `bin-1d-cells`, `bin-2d-cells` or `stat/bindot.typ`
// would therefore restore the cost with the suite still green. That gap is
// accepted, and the call sites carry a comment saying so.

#import "../../src/utils/bin.typ": (
  bin-1d-cells, panel-bin-grid, resolve-bin-grid,
)
#import "../../src/utils/bin-2d.typ": (
  bin-2d-cells, panel-bin-grid-2d, resolve-bin-grid-2d,
)
#import "../../src/aes.typ": aes

#let raw = range(0, 20).map(v => (a: v, b: v * 2))

// --- 1-D: a stashed grid short-circuits the thunk --------------------------

#let params-1d = panel-bin-grid(raw, aes(x: "a"), (bins: 4, binwidth: none))
#assert.eq(params-1d.grid.n-bins, 4)

// The thunk panics if it is called. Reaching the assertion below is the proof
// that the resolver never asked for the values.
#let resolved-1d = resolve-bin-grid(params-1d, () => panic(
  "resolve-bin-grid read its values despite a stashed grid",
))
#assert.eq(resolved-1d.n-bins, 4)
#assert.eq(resolved-1d.lo, 0.0)

// --- 1-D: no stashed grid falls back to the thunk --------------------------

#let derived-1d = resolve-bin-grid((bins: 2, binwidth: none), () => (0, 10))
#assert.eq(derived-1d.n-bins, 2)
#assert.eq(derived-1d.lo, 0)
#assert.eq(derived-1d.width, 5.0)

// --- 2-D: a stashed grid short-circuits both thunks ------------------------

#let params-2d = panel-bin-grid-2d(
  raw,
  aes(x: "a", y: "b"),
  (bins: 4, binwidth: none),
)
#assert.eq(params-2d.grid.x-n-bins, 4)

#let resolved-2d = resolve-bin-grid-2d(
  params-2d,
  () => panic("resolve-bin-grid-2d read its x values despite a stashed grid"),
  () => panic("resolve-bin-grid-2d read its y values despite a stashed grid"),
)
#assert.eq(resolved-2d.x-n-bins, 4)
#assert.eq(resolved-2d.y-n-bins, 4)

// --- 2-D: no stashed grid falls back to both thunks ------------------------

#let derived-2d = resolve-bin-grid-2d(
  (bins: 2, binwidth: none),
  () => (0, 10),
  () => (0, 4),
)
#assert.eq(derived-2d.x-n-bins, 2)
#assert.eq(derived-2d.y-n-bins, 2)
#assert.eq(derived-2d.x-width, 5.0)
#assert.eq(derived-2d.y-width, 2.0)

// --- the call site short-circuits on the stashed grid ---------------------
//
// `bin-1d-cells` is given a stashed grid that no group of these rows would
// derive: four bins over `[0, 20)` against rows spanning `[0, 4]`. The cells it
// emits must follow the stashed partition, which is what the thunk defers to.

#let stashed = (bins: 4, binwidth: none, grid: (lo: 0, n-bins: 4, width: 5.0))
#let cells = bin-1d-cells(
  range(0, 5).map(v => (a: v)),
  "a",
  none,
  stashed,
)
#assert.eq(cells.grid.n-bins, 4)
#assert.eq(cells.grid.width, 5.0)
// All five rows fall in the first stashed bin; a grid derived from the rows
// would have spread them across four bins of width 1.
#assert.eq(cells.counts, (5, 0, 0, 0))

// The two-dimensional builder carries the same contract, so it is pinned the
// same way: a stashed two-by-two grid over `[0, 20)` against rows spanning
// `[0, 4]` puts every row in the first cell.
#let stashed-2d = (
  bins: 2,
  binwidth: none,
  grid: (
    x-lo: 0,
    x-n-bins: 2,
    x-width: 10.0,
    y-lo: 0,
    y-n-bins: 2,
    y-width: 10.0,
  ),
)
#let cells-2d = bin-2d-cells(
  range(0, 5).map(v => (a: v, b: v)),
  "a",
  "b",
  stashed-2d,
)
#assert.eq(cells-2d.grid.x-n-bins, 2)
#assert.eq(cells-2d.grid.x-width, 10.0)
#assert.eq(cells-2d.counts, (5, 0, 0, 0))

bin grid laziness tests passed.
