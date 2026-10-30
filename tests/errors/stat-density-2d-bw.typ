// `stat-density-2d` fails when `bw` is negative.
//
// `bw: -1` used to become 1.0 in silence.
//
// expect: stat-density-2d: bw must be a positive number, `auto`, or an `(x, y)` pair of them; got -1

#import "/lib.typ": stat-density-2d

#stat-density-2d(bw: -1)
