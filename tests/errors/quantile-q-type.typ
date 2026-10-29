// `quantile` checks the type of `q` before its range.
//
// expect: quantile: q must be a number; got "0.5"

#import "/lib.typ": quantile

#quantile((1, 2, 3), q: "0.5")
