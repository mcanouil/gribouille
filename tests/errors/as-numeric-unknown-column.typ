// `as-numeric` fails on a column that the data does not hold.
//
// The two-argument form used to add a new all-`none` column in silence.
//
// expect: as-numeric: col maps to unknown column "b"

#import "/lib.typ": as-numeric

#as-numeric(((a: "1"),), "b")
