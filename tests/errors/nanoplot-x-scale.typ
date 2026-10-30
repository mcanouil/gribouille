// The column domain is numeric, so the x scale of a nanoplot is continuous.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: nanoplot: scales.x must be a continuous scale
// expect: got "discrete"
// expect: Use scale-continuous()

#import "/lib.typ": nanoplot, scale-discrete, scales

#nanoplot(domain-field: "salary", scales: scales(x: scale-discrete()))
