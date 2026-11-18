// A string `outlier-colour` fails under the geom's name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-boxplot: outlier-colour

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-boxplot(outlier-colour: "red")
