// A theme preset rejects a positional argument under its own name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme-minimal: expects named element overrides

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-minimal(element-blank())
