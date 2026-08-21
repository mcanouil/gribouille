// The bin grid resolvers are lazy: a stashed panel-wide grid is answered
// without asking the caller for its values.
//
// `params.grid` is set once per panel by `panel-bin-grid`, so every per-group
// `apply()` call after that already has its partition. Building the value
// arrays for a resolver that will not look at them costs one full pass per
// group, which is why the resolvers take thunks rather than arrays.
//
// These tests pin the resolvers, not their callers. A caller that builds its
// values before wrapping them in a thunk still passes every case here, because
// an eager `entries.map()` has no observable effect. The call sites are
// `bin-1d-cells`, `bin-2d-cells` and `stat/bindot.typ`.

#import "../../src/utils/bin.typ": panel-bin-grid, resolve-bin-grid
#import "../../src/utils/bin-2d.typ": panel-bin-grid-2d, resolve-bin-grid-2d
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

bin grid laziness tests passed.
