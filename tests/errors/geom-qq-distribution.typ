// `geom-qq` lists the valid distributions under its own name.
//
// `distribution: "bogus"` used to fail as `theoretical-quantile` at render time.
//
// expect: geom-qq: distribution must be one of "normal", "uniform", "exponential"; got "bogus"

#import "/lib.typ": geom-qq

#geom-qq(distribution: "bogus")
