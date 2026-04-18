// Shared facet helpers. Generalises the row-filter used by both wrap and grid.

// Filter every prepared layer's data to rows that match all of the given
// (column, value) pairs. When `filters` is empty, returns the layers as-is.
#let filter-layers-multi(prepared, filters) = {
  prepared.map(layer => {
    let new = layer
    new.data = layer.data.filter(row => {
      let keep = true
      for (col, value) in filters {
        if str(row.at(col, default: "")) != value { keep = false; break }
      }
      keep
    })
    new
  })
}

// Collect unique levels of a column across all layers' data, in the order of
// first appearance.
#let levels-for(prepared, var) = {
  let seen = ()
  for layer in prepared {
    for row in layer.data {
      let v = row.at(var, default: none)
      if v == none { continue }
      let s = str(v)
      if not seen.contains(s) { seen.push(s) }
    }
  }
  seen
}
