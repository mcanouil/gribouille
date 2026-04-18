// Dispatch table for stat transforms.
// Keeps render.typ free of per-stat knowledge.

#import "identity.typ" as identity-stat
#import "bin.typ" as bin-stat
#import "count.typ" as count-stat
#import "smooth.typ" as smooth-stat

#let apply-stat(name, data, mapping, params) = {
  if name == none or name == "identity" {
    (data: data, mapping: mapping)
  } else if name == "bin" {
    bin-stat.apply(data, mapping, params: params)
  } else if name == "count" {
    count-stat.apply(data, mapping, params: params)
  } else if name == "smooth" {
    smooth-stat.apply(data, mapping, params: params)
  } else {
    (data: data, mapping: mapping)
  }
}
