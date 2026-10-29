// `stat-function` fails when `fun` is not a function.
//
// `fun: 5` used to raise the raw Typst error `expected function, found integer`.
//
// expect: stat-function: fun must be a function; got 5

#import "/lib.typ": stat-function

#stat-function(fun: 5)
