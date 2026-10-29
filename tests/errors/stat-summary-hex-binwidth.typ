// `stat-summary-hex` fails when `binwidth` is zero.
//
// `binwidth: 0` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: stat-summary-hex: binwidth must be a positive number or an `(x, y)` pair of them; got 0

#import "/lib.typ": stat-summary-hex

#stat-summary-hex(binwidth: 0)
