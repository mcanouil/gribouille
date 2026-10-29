// `stat-ellipse` fails when `level` is not a number.
//
// `level: "a"` used to raise the raw Typst error `cannot compare string and integer`.
//
// expect: stat-ellipse: level must be a number; got "a"

#import "/lib.typ": stat-ellipse

#stat-ellipse(level: "a")
