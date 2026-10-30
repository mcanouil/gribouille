// `as-factor` takes one or two positional arguments.
//
// expect: as-factor: expects `(data, col)` or `(col)`; got 3 positional argument(s)

#import "/lib.typ": as-factor

#as-factor(((a: 1),), "a", "b")
