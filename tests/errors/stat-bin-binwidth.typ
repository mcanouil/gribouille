// `stat-bin` fails when `binwidth` is not positive.
//
// `binwidth: -1` used to be ignored in silence.
//
// expect: stat-bin: binwidth must be a positive number; got -1

#import "/lib.typ": stat-bin

#stat-bin(binwidth: -1)
