// `scales()` fails when a binned colour scale gets fewer than one bin.
//
// `n-breaks: 0` used to raise the raw Typst error `cannot divide by zero` in the
// colour bar.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-steps: n-breaks must be a positive integer; got 0

#import "/lib.typ": scale-steps, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-steps(n-breaks: 0))
