// `stat-density-2d` fails when `n` is below 2.
//
// `n: 1` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: stat-density-2d: n must be an integer of at least 2, or an `(x, y)` pair of them; got 1

#import "/lib.typ": stat-density-2d

#stat-density-2d(n: 1)
