// `stat-boxplot` fails when `coefficient` is negative.
//
// `coefficient: -1` used to make every point an outlier.
//
// expect: stat-boxplot: coefficient must be a non-negative number; got -1

#import "/lib.typ": stat-boxplot

#stat-boxplot(coefficient: -1)
