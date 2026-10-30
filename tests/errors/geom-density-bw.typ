// `geom-density` reports a bad `bw` under its own name.
//
// `bw: -1` used to fail as `stat-density` at render time.
//
// expect: geom-density: bw must be a positive number or `auto`; got -1

#import "/lib.typ": geom-density

#geom-density(bw: -1)
