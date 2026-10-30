// `stat-quantile` fails when `quantiles` is not an array.
//
// `quantiles: 0.5` used to raise the raw Typst error `type float has no method map`.
//
// expect: stat-quantile: quantiles must be an array of probabilities; got 0.5

#import "/lib.typ": stat-quantile

#stat-quantile(quantiles: 0.5)
