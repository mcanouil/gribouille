// `stat-function` fails when `n` is below 2.
//
// `n: 0` used to clamp to 2 in silence.
//
// expect: stat-function: n must be an integer of at least 2; got 0

#import "/lib.typ": stat-function

#stat-function(n: 0)
