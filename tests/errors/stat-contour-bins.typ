// `stat-contour` fails when `bins` is zero.
//
// `bins: 0` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: stat-contour: bins must be a positive integer or `none`; got 0

#import "/lib.typ": stat-contour

#stat-contour(bins: 0)
