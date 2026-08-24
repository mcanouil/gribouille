// The same failure reached through a palette alias names the hop it walked, so
// the reader is sent to the palette entry rather than to the role that points
// at it.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: color.primary declares variants but names neither
// expect: reached through "brand-red"

#import "/lib.typ": theme-brand

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-brand((
  color: (
    palette: ("brand-red": (bright: "#E94C3D")),
    primary: "brand-red",
  ),
))
