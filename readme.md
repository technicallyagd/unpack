# Module Unpack

Array/Sequence/Object destructuring/unpacking macros attempt to quench the thirst of (Python, ES6, et al.)-spoiled people.

## Example Usage

```nim

let someSeq = @[1, 1, 2, 3, 5]
someSeq.lunpack(a,b,c) # creates a, b, c with 'let'
echo a, b, c # 112
someSeq.vunpack(d,e) # creates d,e with 'var'

```

## TODO

- Docs
- Tests
- Support arbitrary entity with `[]` defined to use as index
- Maybe we can also support tables?
