// A nanoplot theme is a theme dictionary, not the preset function itself.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrases below.
//
// expect: nanoplot: theme must be a theme dictionary
// expect: Call the preset, as in theme: theme-bw()

#import "/lib.typ": nanoplot, theme-bw

#nanoplot(domain-field: "salary", theme: theme-bw)
