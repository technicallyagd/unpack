# Module Unpack

Array/Sequence/Object destructuring/unpacking macros attempt to quench the thirst of (Python, ES6, et al.)-spoiled people.

Inspired by @Yardanico's [unpackarray.nim](https://gist.github.com/Yardanico/b6fee43f6da8a3bbf0fe048063357115)

## Example Usage

```nim

let someSeq = @[1, 1, 2, 3, 5]
someSeq.lunpack(a,b,c) # creates a, b, c with 'let'
# is expanded into:
# let
#   a = someSeq[0]
#   b = someSeq[1]
#   c = someSeq[2]

# or equivalently:
[a2, b2, c2] <- someSeq

echo a, b, c # 112
someSeq.vunpack(d,e) # creates d,e with 'var'

# or equivalently:
[var d2, e2] <- someSeq

someSeq.unpack(a,c) # assigns someSeq[0] to a, someSeq[1] to c

# or equivalently:
[a2, c2] <-- someSeq # yes, <-- for assignment; <- for definitions. This is not a typo.

type
  Person = object
    name, job: string

let tim = Person(name: "Tim", job: "Fluffer")

tim.lunpack(name, job) # creates name, job with let and assign respective member values to them

# or equivalently:
# {name, job} <- tim

tim.lunpack(job, otherName = name) # you can also unpack into custom names using '='

# or equivalently:
# {job, name: otherName} <- tim
# Adheres to ES6 syntax, hence the opposite order

# will not invoke proc chain multiple times
tim.someProcWithSideEffects(arg).lunpack(name, job)

# or equivalently:
# {name, job} <- tim.someProcWithSideEffects(arg)

# is expanded into:
# let someUniqueSym1212498 = tim.someProcWithSideEffects(arg)
# let
#   name = someUniqueSym1212498.name
#   job = someUniqueSym1212498.job
```

See `tests/test1.nim` for more usages.

## Notes

### Unpacking objects with `[]` as indexing operator

Some [packages](https://github.com/mratsim/Arraymancer/blob/master/src/tensor/backend/metadataArray.nim#L17) uses `object` to implement array-like structure. For cases like this, `lunpack/vunpack/unpack` won't work. Use `<-` syntax instead.

## TODO

- Docs
- Maybe we can also support tables?
- Spread operator

## Suggestions and PR's are welcome

Especially if you know how to make this macro easier to use. Also, if you know any other existing package that does this kind of stuff better, please let me know, thank you.
