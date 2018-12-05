# Change Log

## v0.2.0

- Deprecating `unpack`, `lunpack`, and `vunpack` in favor of `unpackObject`, `unpackSeq`, `aUnpackObjec`, and `aUnpackSeq`. The new interface is more similar to the `<-` syntax, and the programmers will have more control over how the data source will be unpacked.

- Adds example and tests to demonstrate how to flexibly unpack named tuples (like a boss).

- Sequence unpacking will skip the `_` entirely now.

## v0.1.0

- Initially only has `unpack`, `lunpack`, and `vunpack` macros allows unpacking after chaining but has some limitation. Hated by most (N=2).

- Later added `<--` and `<-` syntax as suggested by @alehander42.
