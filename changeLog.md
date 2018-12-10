# Change Log

## v0.4.0

- Supports nested unpacking.

## v0.3.2

- Implements hack to enable rest unpacking after `var`. i.e. `[var _ as *a, b] <- someSeq`

## v0.3.1

- Renames rename syntax. From the originally confusing `{name: anotherName} <- tim` and `unpackObject(name = anotherName)` to clear and descriptive `as` for both. (i.e. `{name as anotherName} <- tim` and `unpackObject(name as anotherName)`.)

## v0.3.0

- Adds `*` rest operator support for unpacking sequence-like stuff.

## v0.2.0

- Deprecating `unpack`, `lunpack`, and `vunpack` in favor of `unpackObject`, `unpackSeq`, `aUnpackObject`, and `aUnpackSeq`. The new interface is more similar to the `<-` syntax, and the programmers will have more control over how the data source will be unpacked.

- Adds example and tests to demonstrate how to flexibly unpack named tuples (like a boss).

- Sequence unpacking will skip the `_` entirely now.

## v0.1.0

- Inspired by @Yardanico's [unpackarray.nim](https://gist.github.com/Yardanico/b6fee43f6da8a3bbf0fe048063357115)

- Initially only has `unpack`, `lunpack`, and `vunpack` macros. These allows unpacking after chaining but has some limitation. Hated by most (N=2).

- Later added `<--` and `<-` syntax as suggested by @alehander42.
