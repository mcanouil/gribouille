// Column type inference and number parsing.
// Typst's csv() gives strings, so gribouille parses them on demand.

#let _numeric-re = regex("^\\s*-?\\d+(\\.\\d+)?([eE][-+]?\\d+)?\\s*$")

#let parse-number(v) = {
  if v == none { return none }
  if type(v) == int { return float(v) }
  if type(v) == float { return v }
  if type(v) == str {
    let t = v.trim()
    if t == "" { return none }
    if t.match(_numeric-re) == none { return none }
    return float(t)
  }
  none
}

#let is-numeric-value(v) = {
  if v == none or v == "" { return true }
  if type(v) == int or type(v) == float { return true }
  if type(v) == str and v.trim().match(_numeric-re) != none { return true }
  false
}

#let infer-column-type(values) = {
  let non-empty = values.filter(v => v != none and v != "")
  if non-empty.len() == 0 { return "unknown" }
  if non-empty.all(is-numeric-value) { return "numeric" }
  "string"
}
