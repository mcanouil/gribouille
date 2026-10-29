// `stat-quantile` fails when a quantile is outside (0, 1).
//
// `quantiles: (1.5,)` used to render with no error.
//
// expect: stat-quantile: every quantile must be in (0, 1); got 1.5

#import "/lib.typ": stat-quantile

#stat-quantile(quantiles: (1.5,))
