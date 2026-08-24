// `theme-brand` fails when a semantic colour is a dictionary that carries
// neither a `light` nor a `dark` key.
//
// The message names the role at fault, as every other failure in the brand
// parser does.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: color.primary
// expect: a `light` or `dark` key

#import "/lib.typ": theme-brand

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-brand((color: (primary: (bright: "#E94C3D"))))
