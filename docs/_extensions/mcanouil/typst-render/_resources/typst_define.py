"""Pass Python values into Typst code cells of the document.

Emits a Pandoc YAML metadata block carrying a hex-encoded JSON payload that
the typst-render Lua filter ingests and converts into a
`#let typst_define = (...)` binding available in every `{typst}` code block
of the document. The filter ingests the metadata before it processes any
block, so a block above this call sees the values as well.
"""

import importlib

# Across-call accumulator. Each call updates this dict (last-write-wins on
# names, insertion order preserved per Python 3.7+) and re-emits the full
# accumulated payload so pandoc's metadata-block merge ends up with the
# right final state.
_typst_define_state = {}


def _convert(v):
    """Convert pandas/polars/numpy values to JSON-serialisable forms."""
    converters = (
        ("pandas", "DataFrame", lambda x: x.to_dict(orient="list")),
        ("polars", "DataFrame", lambda x: x.to_dict(as_series=False)),
        ("numpy", "ndarray", lambda x: x.tolist()),
    )
    for module_name, type_name, convert in converters:
        if importlib.util.find_spec(module_name) is None:
            continue
        module = importlib.import_module(module_name)
        if isinstance(v, getattr(module, type_name)):
            return convert(v)
    return v


def typst_define(**kwargs):
    import json

    from IPython.display import Markdown, display

    for k, v in kwargs.items():
        _typst_define_state[k] = _convert(v)
    payload = {
        "contents": [{"name": k, "value": v} for k, v in _typst_define_state.items()]
    }
    encoded = json.dumps(payload).encode("utf-8").hex()
    display(Markdown(f"\n---\ntypst-define: {encoded}\n---\n"))
