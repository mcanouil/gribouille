// `stat-contour` fails when `breaks` is not an array.
//
// `breaks: 3` used to raise the raw Typst error `type integer has no method filter`.
//
// expect: stat-contour: breaks must be an array of numbers or `auto`; got 3

#import "/lib.typ": stat-contour

#stat-contour(breaks: 3)
