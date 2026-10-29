// `count` fails when a grouping column is named `n`, the name of its tally,
// and its hint names the fix that `count` allows.
//
// expect: count: aggregation "n" collides with a grouping column
// expect: Rename the column `n` before counting

#import "/lib.typ": count

#count(((n: 1),), "n")
