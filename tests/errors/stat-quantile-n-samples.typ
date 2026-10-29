// `stat-quantile` fails when `n-samples` is zero.
//
// `n-samples: 0` used to raise the raw Typst error `cannot divide by zero`.
//
// expect: stat-quantile: n-samples must be a positive integer; got 0

#import "/lib.typ": stat-quantile

#stat-quantile(n-samples: 0)
