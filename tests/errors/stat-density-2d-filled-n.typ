// `stat-density-2d-filled` fails when `n` is zero.
//
// `n: 0` used to raise the raw Typst error `expected integer, found none`.
//
// expect: stat-density-2d-filled: n must be an integer of at least 2, or an `(x, y)` pair of them; got 0

#import "/lib.typ": stat-density-2d-filled

#stat-density-2d-filled(n: 0)
