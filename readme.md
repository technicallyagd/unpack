# Module Unpack

Array/Sequence/Object destructuring/unpacking macros attempt to quench the thirst of (Python, ES6, et al.)-spoiled people.

Inspired by @Yardanico's [unpackarray.nim](https://gist.github.com/Yardanico/b6fee43f6da8a3bbf0fe048063357115)

## Installation

```cli
nimble install unpack
```

## Example Usage

```nim
import unpack

let someSeq = @[1, 1, 2, 3, 5]
someSeq.unpackSeq(a, b, c) # creates a, b, c with 'let'
# is expanded into:
# let
#   a = someSeq[0]
#   b = someSeq[1]
#   c = someSeq[2]

# or equivalently:
[a2, b2, c2] <- someSeq

someSeq.unpackSeq(a3, _, _, b3) # use `_` to skip index
# is expanded into:
# let
#   a3 = someSeq[0]
#   b3 = someSeq[3]

echo a, b, c                  # 112
someSeq.unpackSeq(var d, e) # creates d,e with 'var'

# or equivalently:
[var d2, e2] <- someSeq

someSeq.aUnpackSeq(d2, e2) # assigns someSeq[0] to d2, someSeq[1] to e2

# or equivalently:
[d2, e2] <-- someSeq
# yes, <-- for assignment; <- for definitions.
# This is not a typo.

type
  Person = object
    name, job: string

let tim = Person(name: "Tim", job: "Fluffer")

# create name, job with let and assign respective member values to them
tim.unpackObject(name, job)

# or equivalently:
# {name, job} <- tim

# is expanded into:
# let
#   name = tim.name
#   job = tim.job

# you can also unpack into custom names using ':'
{job: someJob, name: otherName} <- tim
# Adheres to ES6 syntax

# or equivalently:
tim.unpackObject(job = someOtherJob, name = someOtherName)

# is expanded into:
# let
#   someOtherName = tim.name
#   someOtherJob = tim.job

var
  secreteState, arg = 0
proc someProcWithSideEffects(person: Person, input: int): Person =
  secreteState += 1
  {var job, name: newName} <- person
  newName &= $input
  result = Person(name: newName, job: job)

# using this at the end of proc chain will not invoke proc chain multiple times
tim.someProcWithSideEffects(arg).unpackObject(name = tim0, job = job0)

# or equivalently:
# {name: tim0, job: job0} <- tim.someProcWithSideEffects(arg)

# is expanded into:
# let someUniqueSym1212498 = tim.someProcWithSideEffects(arg)
# let
#   tim0 = someUniqueSym1212498.name
#   job0 = someUniqueSym1212498.job

# if you haven't noticed,
# this means we can unpack named tuples like objects
type
  SomeTuple = tuple[x, y, z, i, j, k: int; l, m: string]

let someTuple = (1, 3, 7, 0, 3, 6, "so", "lengthy").SomeTuple

# with vanilla nim, to get arbitrary fields
let (_, diz, _, iz, _, _, _, it) = someTuple
# it gets lengthy

# with this package
{y: diz2, i: iz2, m: it2} <- someTuple
# Mind. Blown.

# also, if you only care about the first three items
[nice, n, sweet] <- someTuple

# with vanilla nim
let (youNeedTo, writeSoMany, underscoresMan, _, _, _, _, _) = someTuple

# to be continued...
```

See `tests/test1.nim` for more usages.

## Notes

### About the syntax

#### Using `let` in [] and {} is not allowed

Yes, I also wanted to have the natural `[let x, y] <- someSeq` syntax for defining new symbol with let, `[x, y] <- someSeq` for assignment, but the compiler deems it illegal. I ended up making settle with more verbose assignment syntax since I anticipate it being used less often.

#### About `=` in unpackObject

It is quite weird to see `name = someName` and then `someName` is the symbol being created/assigned to. It is this way only to match the `name : someName` used in `<-` macro. I would also love be able to use `:` in `unpackObject(name : someName)`, but this is also illegal. If people really hate this, we could use other symbol to replace `=`, suggestions are welcome.

## TODO

- Docs
- Maybe we can also support tables?
- Spread operator

## Suggestions and PR's are welcome

Especially if you know how to make this macro easier to use. Also, if you know any other existing package that does this kind of stuff better, please let me know, thank you.
