// `geom-density-2d` reports a bad `binwidth` under its own name.
//
// `binwidth: 0` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: geom-density-2d: binwidth must be a positive number or `none`; got 0

#import "/lib.typ": geom-density-2d

#geom-density-2d(binwidth: 0)
