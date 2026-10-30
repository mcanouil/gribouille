// A type failure behind an alias names the hop it walked.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: color.primary must be a hex colour string
// expect: reached through "brand-red"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-brand((
  color: (
    palette: ("brand-red": (light: (x: 1))),
    primary: "brand-red",
  ),
))
