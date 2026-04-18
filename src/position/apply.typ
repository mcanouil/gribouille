// Position adjustment dispatcher. Sits between stat and render in
// `_prepare-layer`.

#import "identity.typ"
#import "stack.typ"
#import "dodge.typ"
#import "fill.typ" as fill-mod

#let apply-position(name, data, mapping, params: (:)) = {
  if name == none or name == "identity" {
    return identity.apply(data, mapping, params: params)
  }
  if name == "stack" { return stack.apply(data, mapping, params: params) }
  if name == "dodge" { return dodge.apply(data, mapping, params: params) }
  if name == "fill" { return fill-mod.apply(data, mapping, params: params) }
  panic("Unknown position adjustment: " + name)
}
