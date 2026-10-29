// `scales()` fails when `scale-manual()` gets no value.
//
// The message used to come from an internal helper at render time, and named a
// function that does not exist.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-manual: values must be a non-empty array; got ()

#import "/lib.typ": scale-manual, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-manual())
