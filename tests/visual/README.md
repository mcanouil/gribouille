# Visual regression tests

Golden-image tests.

Each example in `/examples/` is compiled to PNG and diffed byte-for-byte against a committed golden stored here.
CI fails on diff; goldens are refreshed deliberately via a dedicated workflow.
