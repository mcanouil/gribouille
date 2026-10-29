// `mean-cl-boot` fails on a resample count below 1, and does not clamp it.
//
// expect: mean-cl-boot: n-boot must be a positive integer; got 0

#import "/lib.typ": mean-cl-boot

#mean-cl-boot((1, 2, 3), n-boot: 0)
