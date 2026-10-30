// `nanoplot()` with no `domain-field` has no way to read the shared domain.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: nanoplot: domain-field must be a field name
// expect: got none
// expect: Name the record field that holds the x values

#import "/lib.typ": aes, geom-point, nanoplot

#nanoplot(mapping: aes(x: "salary", y: "y"), layers: (geom-point(),))
