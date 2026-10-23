// Drift guard between AES-KEYS and the mapping keys the code reads.
// Every key that `aes()` accepts must be read by some geom, stat, position,
// or core path, and every key that one of them reads must be accepted by
// `aes()`. A key on one side only is a defect: `aes()` accepts a key that
// nothing draws, or the code reads a key that `aes()` rejects.

#import "../../src/aes-keys.typ": AES-KEYS, CORE-READS
#import "../../src/geom/registry.typ": GEOMS
#import "../../src/stat/apply.typ": _STATS
#import "../../src/position/apply.typ": POSITION-READS
#import "../../src/utils/group.typ": group-aesthetics

#let declared = (
  GEOMS.values().map(g => g.spec.reads).flatten()
    + _STATS.values().map(s => s.reads).flatten()
    + POSITION-READS.values().flatten()
    + CORE-READS
).dedup()
#let unread = AES-KEYS.filter(k => k not in declared)
#let rejected = declared.filter(k => k not in AES-KEYS)
#assert(
  unread == (),
  message: "aes() accepts keys nothing reads: " + unread.join(", "),
)
#assert(
  rejected == (),
  message: "code reads keys aes() rejects: " + rejected.join(", "),
)

// Grouping reads its aesthetics for every layer, so CORE-READS holds them.
#assert(group-aesthetics.all(k => k in CORE-READS))

aes-keys union drift guard passed.
