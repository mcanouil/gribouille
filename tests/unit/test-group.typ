// Group-key and group-cols utility tests.

#import "../../src/utils/group.typ": (
  bucket-by-col, expose-shared-positional, group-aesthetics, group-cols,
  group-key, group-plan, partition-by-group, plan-key,
)
#import "../../src/aes.typ": aes
#import "../../src/data.typ": as-factor
#import "../../src/utils/late-binding.typ": after-stat

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

// An `as-factor` x re-attached to the output mapping (a `mapping-ref` dict, not
// a string) must be unwrapped before it is used as a column key. Here the stat
// kept x under its source column, so out-col unwraps to "g" == src and the
// column is already present: no crash, no double exposure.
#let same-rows = ((g: "a", y: 1.0), (g: "b", y: 2.0))
#let factor-out = expose-shared-positional(
  same-rows,
  m-same,
  (x: as-factor("g"), y: "y"),
)
#assert.eq(factor-out.at(0).at("g"), "a")
#assert.eq(factor-out.at(1).at("g"), "b")

// y reused by a grouping aesthetic is exposed too (axis: "x" summary path).
#let y-rows = ((x: 1.0, y: "lo"),)
#let m-fill-is-y = aes(x: "x", y: "h", fill: "h")
#let y-exposed = expose-shared-positional(y-rows, m-fill-is-y, (x: "x", y: "y"))
#assert.eq(y-exposed.at(0).at("h"), "lo")

// --- sourceless markers carry no grouping variable ---
// An `after-stat` marker names a column that does not exist until the stat
// has run, so pre-stat grouping must skip it instead of using the marker
// dict as a column name.

#let m-after-stat = aes(x: "x", y: "y", fill: after-stat("_sign"))
#assert.eq(group-key(row1, m-after-stat), "_all")
#assert.eq(group-cols(m-after-stat), ())

// --- the plan and the key it produces ---
// Which aesthetics can group is a property of the mapping, so it is resolved
// once and spent per row. Only the data-type mode leaves a decision to the
// row, where a cell that is numeric does not group.

#let m-colour = aes(x: "x", y: "y", colour: "g")
#assert.eq(group-plan(m-colour), ((col: "g", by-value: true),))
#assert.eq(
  group-plan(m-colour, trained: (colour: (type: "discrete", domain: ("a",)))),
  ((col: "g", by-value: false),),
)
#assert.eq(group-plan(aes(x: "x", y: "y")), ())

// The key a plan makes is the key the one-shot helper makes.
#let rows-mixed = ((x: 1, y: 2, g: "a"), (x: 2, y: 3, g: 4))
#for row in rows-mixed {
  assert.eq(plan-key(group-plan(m-colour), row), group-key(row, m-colour))
}

// A missing cell keys as the empty string, so a row with no value for the
// grouping column still lands in a bucket rather than being dropped.
#assert.eq(group-key((x: 1, y: 2), m-colour), "")

// --- partitioning keeps first-appearance order and every row ---
#let rows = (
  (x: 1, g: "b"),
  (x: 2, g: "a"),
  (x: 3, g: "b"),
  (x: 4, g: "a"),
  (x: 5, g: "b"),
)
#let parts = partition-by-group(rows, aes(x: "x", y: "y", colour: "g"))
#assert.eq(parts.map(p => p.key), ("b", "a"))
#assert.eq(parts.map(p => p.data.len()), (3, 2))
#assert.eq(parts.at(0).data.map(r => r.x), (1, 3, 5))
#assert.eq(parts.at(1).data.map(r => r.x), (2, 4))

// One bucket is the worst case for the copy-on-push pattern this avoids, and
// it must still answer every row in order.
#let one = partition-by-group(rows, aes(x: "x", y: "y"))
#assert.eq(one.len(), 1)
#assert.eq(one.at(0).key, "_all")
#assert.eq(one.at(0).data.map(r => r.x), (1, 2, 3, 4, 5))

// --- bucket-by-col: first-appearance order, empty values dropped ---
#let col-rows = (
  (v: "x", i: 0),
  (v: "y", i: 1),
  (v: "", i: 2),
  (v: "x", i: 3),
)
#let cols = bucket-by-col(col-rows, "v")
#assert.eq(cols.len(), 2)
#assert.eq(cols.at(0).map(r => r.i), (0, 3))
#assert.eq(cols.at(1).map(r => r.i), (1,))

Group tests passed.
