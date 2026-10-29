// `stat-bin-hex` fails when `bins` is negative.
//
// `bins: -3` used to render with no error.
//
// expect: stat-bin-hex: bins must be a positive integer or an `(x, y)` pair of them; got -3

#import "/lib.typ": stat-bin-hex

#stat-bin-hex(bins: -3)
