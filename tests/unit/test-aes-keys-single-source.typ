// Drift guard for the canonical aesthetic-key list in src/aes-keys.typ.
// `aes()` keeps a hand-written named signature (Typst cannot splat one from
// an array), so this test pins it to AES-KEYS and pins annotate's routed
// subset to be a subset of the same list.

#import "../../src/aes-keys.typ": AES-KEYS
#import "../../src/aes.typ": aes
#import "../../src/annotate.typ": _aes-keys-for, _geom-table, _params-only
#import "../../src/geom/registry.typ": GEOMS

// `aes()` exposes exactly the canonical keys (its return dict also carries the
// `kind` tag, which is not an aesthetic).
#let aes-keys = aes().keys().filter(k => k != "kind")
#assert.eq(aes-keys.sorted(), AES-KEYS.sorted())

// Every key annotate routes to its inline dataset is a real aesthetic.
#for geom in _geom-table.keys().filter(g => g not in _params-only) {
  let reads = GEOMS.at(geom).spec.reads
  assert(_aes-keys-for(geom, reads).all(k => k in AES-KEYS), message: geom)
}

aes-keys single-source drift guard passed.
