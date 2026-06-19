// `_resolve-alt`: plot(alt:) wins, else labels(alt:) fills in.

#import "../../src/plot.typ": _resolve-alt
#import "../../src/labels.typ": labels

// --- explicit plot alt wins over a labels alt -------------------------------

#assert.eq(_resolve-alt("explicit", labels(alt: "from labels")), "explicit")

// --- labels alt fills in when plot alt is unset -----------------------------

#assert.eq(_resolve-alt(none, labels(alt: "from labels")), "from labels")

// --- both unset resolves to none ------------------------------------------
// labels(alt:) defaults to `auto`, which counts as unset.

#assert.eq(_resolve-alt(none, labels(title: "t")), none)
#assert.eq(_resolve-alt(none, none), none)

Labels alt tests passed.
