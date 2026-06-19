// Drift guard for the canonical aesthetic-key list in src/aes-keys.typ.
// `aes()` keeps a hand-written named signature (Typst cannot splat one from
// an array), so this test pins it to AES-KEYS and pins annotate's routed
// subset to be a subset of the same list.

#import "../../src/aes-keys.typ": AES-KEYS
#import "../../src/aes.typ": aes
#import "../../src/annotate.typ": _default-aes-keys

// `aes()` exposes exactly the canonical keys (its return dict also carries the
// `kind` tag, which is not an aesthetic).
#let aes-keys = aes().keys().filter(k => k != "kind")
#assert.eq(aes-keys.sorted(), AES-KEYS.sorted())

// Every key annotate routes to its inline dataset is a real aesthetic.
#assert(_default-aes-keys.all(k => k in AES-KEYS))

aes-keys single-source drift guard passed.
