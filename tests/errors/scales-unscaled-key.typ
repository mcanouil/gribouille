// `scales()` fails for an aesthetic that has no scale.
//
// `width` is a mapping key, but no scale trains on it, so a scale bound to it
// used to be accepted and then ignored. `scales()` now accepts only the
// aesthetics that scale training knows.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scales: aesthetic must be one of

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(width: scale-continuous())
