// `stat-bin` fails when `bins` is not a whole number.
//
// `bins: 2.5` used to raise the raw Typst error `expected integer, found float`.
//
// expect: stat-bin: bins must be a positive integer; got 2.5

#import "/lib.typ": stat-bin

#stat-bin(bins: 2.5)
