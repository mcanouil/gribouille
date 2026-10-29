// `quantiles` fails when its probabilities are not in ascending order.
//
// Descending probabilities used to give ymin above ymax.
//
// expect: quantiles: probs must be in ascending order; got (0.75, 0.5, 0.25)

#import "/lib.typ": quantiles

#quantiles((1, 2, 3), probs: (0.75, 0.5, 0.25))
