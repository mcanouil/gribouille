// keisen asks a nanoplot axis for the "top" or the "bottom" side only.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: nanoplot: side must be one of "top", "bottom"
// expect: got "left"

#import "/lib.typ": nanoplot

#(nanoplot(domain-field: "salary").axis)(
  domain: (0, 1),
  width: 3cm,
  side: "left",
)
