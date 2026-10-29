// `geom-histogram` reports a bad `bins` under its own name.
//
// `bins: 0` used to fail as `bin-config` at render time.
//
// expect: geom-histogram: bins must be a positive integer; got 0

#import "/lib.typ": geom-histogram

#geom-histogram(bins: 0)
