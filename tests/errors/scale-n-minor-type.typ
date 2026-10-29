// `scales()` fails when `n-minor` is not a count.
//
// It used to raise the raw Typst error `invalid integer`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: n-minor must be a non-negative integer or `auto`; got "a"

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(n-minor: "a"))
