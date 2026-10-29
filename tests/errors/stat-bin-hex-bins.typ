// `stat-bin-hex` fails when `bins` is zero.
//
// `bins: 0` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: stat-bin-hex: bins must be a positive integer or an `(x, y)` pair of them; got 0

#import "/lib.typ": stat-bin-hex

#stat-bin-hex(bins: 0)
