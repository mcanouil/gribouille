// Group-key and group-cols utility tests.

#import "../../src/utils/group.typ": (
  expose-shared-positional, group-aesthetics, group-cols, group-key,
)
#import "../../src/aes.typ": aes
#import "../../src/data.typ": as-factor

// --- group-aesthetics canonical order ---

#assert.eq(group-aesthetics, ("group", "colour", "fill", "linetype", "shape"))

// --- group-key: no grouping aesthetics ---

#let row1 = (x: 1, y: 2)
#let m-xy = aes(x: "x", y: "y")
#assert.eq(group-key(row1, m-xy), "_all")

// --- group-key: string colour → discrete → included ---

#let row-str = (x: 1, y: 2, g: "a")
#let m-colour-str = aes(x: "x", y: "y", colour: "g")
#assert.ne(group-key(row-str, m-colour-str), "_all")
#assert.eq(group-key(row-str, m-colour-str), "a")

// --- group-key: numeric colour → continuous → excluded (data-type mode) ---

#let row-num = (x: 1, y: 2, g: 42)
#let m-colour-num = aes(x: "x", y: "y", colour: "g")
#assert.eq(group-key(row-num, m-colour-num), "_all")

// --- group-key: numeric colour forced discrete via as-factor → included ---

#let m-colour-factor = aes(x: "x", y: "y", colour: as-factor("g"))
#assert.ne(group-key(row-num, m-colour-factor), "_all")
#assert.eq(group-key(row-num, m-colour-factor), "42")

// --- group-key: explicit "group" aesthetic always included regardless of type ---

#let m-group-num = aes(x: "x", y: "y", group: "g")
#assert.ne(group-key(row-num, m-group-num), "_all")
#assert.eq(group-key(row-num, m-group-num), "42")

// --- group-key: scale-aware mode with trained discrete scale ---

#let trained-discrete = (
  colour: (type: "discrete", domain: ("a", "b"), spec: none),
)
#let trained-continuous = (
  colour: (type: "continuous", domain: (0.0, 100.0), spec: none),
)

// String colour, trained as discrete → included.
#assert.eq(group-key(row-str, m-colour-str, trained: trained-discrete), "a")

// Numeric colour, trained as continuous → excluded.
#assert.eq(
  group-key(row-num, m-colour-num, trained: trained-continuous),
  "_all",
)

// Numeric colour, trained as discrete (user-supplied scale) → included.
#assert.eq(group-key(row-num, m-colour-num, trained: trained-discrete), "42")

// --- group-key: x/y column is not used for grouping even if also mapped ---

#let row-same = (x: "a", y: 2, g: "a")
#let m-colour-same-as-x = aes(x: "x", y: "y", colour: "x")
#assert.eq(group-key(row-same, m-colour-same-as-x), "_all")

// --- group-key: canonical priority (group before colour) ---

#let row-multi = (x: 1, y: 2, g: "grp", c: "col")
#let m-multi = aes(x: "x", y: "y", group: "g", colour: "c")
// Both contribute; group key is "grp\u{1}col".
#let key-multi = group-key(row-multi, m-multi)
#assert.ne(key-multi, "_all")
#assert(key-multi.starts-with("grp"))

// --- group-cols ---

// Returns column names (not aesthetic names), in canonical priority order.
#let m-fill-colour = aes(x: "x", y: "y", fill: "f", colour: "c")
#assert.eq(group-cols(m-fill-colour), ("c", "f"))

#let m-no-group = aes(x: "x", y: "y")
#assert.eq(group-cols(m-no-group), ())

// fill mapped to same column as x → excluded.
#let m-fill-is-x = aes(x: "x", y: "y", fill: "x")
#assert.eq(group-cols(m-fill-is-x), ())

// --- expose-shared-positional ---

// Stat output rows keyed by the generic "x"; the source column was "g" and a
// grouping aesthetic reuses it, so "g" is exposed carrying the "x" value.
#let stat-rows = ((x: "a", y: 1.0), (x: "b", y: 2.0))
#let m-same = aes(x: "g", y: "y", fill: "g")
#let out-map = (x: "x", y: "y")
#let exposed = expose-shared-positional(stat-rows, m-same, out-map)
#assert.eq(exposed.at(0).at("g"), "a")
#assert.eq(exposed.at(1).at("g"), "b")
// The generic key is preserved alongside the exposed source column.
#assert.eq(exposed.at(0).x, "a")

// Differing-column case: fill maps to a column other than x → no-op.
#let m-diff = aes(x: "g", y: "y", fill: "k")
#let not-exposed = expose-shared-positional(stat-rows, m-diff, out-map)
#assert.eq(not-exposed.at(0).keys().contains("g"), false)

// No grouping aesthetic → no-op.
#let m-plain = aes(x: "g", y: "y")
#assert.eq(
  expose-shared-positional(stat-rows, m-plain, out-map)
    .at(0)
    .keys()
    .contains("g"),
  false,
)

// Already-present source column is not overwritten.
#let pre-rows = ((x: "a", g: "keep"),)
#let pre = expose-shared-positional(pre-rows, m-same, (x: "x"))
#assert.eq(pre.at(0).at("g"), "keep")

// y reused by a grouping aesthetic is exposed too (axis: "x" summary path).
#let y-rows = ((x: 1.0, y: "lo"),)
#let m-fill-is-y = aes(x: "x", y: "h", fill: "h")
#let y-exposed = expose-shared-positional(y-rows, m-fill-is-y, (x: "x", y: "y"))
#assert.eq(y-exposed.at(0).at("h"), "lo")

Group tests passed.
