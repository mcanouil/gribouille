// `geom-blank` does not tell the user to map a key that is not an aesthetic.
//
// `geom-blank` accepts no constant. For a name such as `foo`, the hint used to
// say "Map the key in aes() instead", but `aes()` rejects `foo` too.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: Remove the argument, or map the key in aes() if it is an aesthetic.

#import "/lib.typ": geom-blank

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-blank(foo: 1)
