# Unpack

Array/Sequence/Object destructuring/unpacking macros attempt to quench the thirst of (Python, ES6, et al.)-spoiled people.

## This is a rapidly changing package

The syntax and functionality of each macro are still evolving daily/hourly. Please check out [changeLog.md](changeLog.md) to see the recent changes. I will keep deprecated syntax for a few release while triggering compiler warnings to nudge people to new syntax, but they will be removed eventually.

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

# you can also unpack into custom names using 'as'
{job as someJob, name as otherName} <- tim

# or equivalently:
tim.unpackObject(job as someOtherJob, name as someOtherName)

# is expanded into:
# let
#   someOtherName = tim.name
#   someOtherJob = tim.job

var
  secreteState, arg = 0
proc someProcWithSideEffects(person: Person, input: int): Person =
  secreteState += 1
  {var job, name as newName} <- person
  newName &= $input
  result = Person(name: newName, job: job)

# using this at the end of proc chain will not invoke proc chain multiple times
tim.someProcWithSideEffects(arg).unpackObject(name as tim0, job as job0)

# or equivalently:
# {name as tim0, job as job0} <- tim.someProcWithSideEffects(arg)

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
{y as diz2, i as iz2, m as it2} <- someTuple
# Mind. Blown.

# also, if you only care about the first three items
[nice, n, sweet] <- someTuple

# with vanilla nim
let (youNeedTo, writeSoMany, underscoresMan, _, _, _, _, _) = someTuple

# to be continued...
```

See [tests/theTest.nim](tests/theTest.nim) for more usages.

## Provisional Features

Following features are implemented but the syntax or their actual effects are still in question.

### Rest operator for unpacking sequences

Like in Python (`*a,b = range(5)`) and modern JavaScript `let [a,...b] = someArray`, you can put the rest of the sequence into a new sequence. I haven't decided on the actual prefix to use yet, but I am settling on `*` as used in Python for now. If you have better ideas, please start an issue to discuss other options.

```nim

import unpack

let mamaHen = @[3, 4, 5, 6, 7]

[a, b, *sneakyFox] <- mamaHen

# is expanded into:
# let
#   a = mamaHen[0]
#   b = mamaHen[1]
#   sneakyFox = mamaHen[2..^1]

assert(sneakyFox == @[5, 6, 7])

[*sloppySavior, e] <- sneakyFox

assert(sloppySavior == @[5, 6])

# Perhaps the variable naming may be a bit mis-leading,
# since mamaHen[x..y] creates a new sequence and copy the slice into it,
# so rather than stealing, the sneakyFox actually cloned(?) whatever mamaHen had with her

# You can use *_ to skip the beginning
[*_, pickyFox] <- mamaHen

assert(pickyFox == 7)

# It's okay to take the middle chunk too.
[f, g, *randomFox, _, h] <- mamaHen

assert([f, g, h] == [3, 4, 7])
assert(randomFox == @[5])

# Due to restriction from nim's grammar, `*` following `var`
# is not allowed. Adding `_ as` before it is the current hack I chose to bypass this.
[var _ as *boldFox, i, j] <- mamaHen

assert([i, j] == [6, 7])
assert(boldFox == @[3, 4, 5])

# They are indeed created with var.
i = 12
boldFox[2] = 123

assert(i == 12)
assert(boldFox == @[3, 123, 5])

```

Under the hood, `unpack` just attaches `[countFromStart..^countFromEnd]` to whatever you throw at it, so anything that has slice operator implemented should work. Which also brings us to our first caveat.

#### Caveat

##### Doesn't Work on tuples

Unless you implement the `..` operator (and its friends) yourself though.

##### Only one rest operator per unpack

`[*a, *b, c] <- someSeq` is not allowed. It might be possible, but I think it will be really messy (plus I am lazy). Same restriction applies to both Python and JavaScript, so I think it's okay to skip this part for now.

##### Can't guard against incorrect index access at compile time

Since we have no way to know the sequence length at compile time, (well, at least I don't know a way). We can't know if you are trying to do something goofy like:

```nim
[a, b, *c, d, e] <- @[1,2,3]
```

## Notes

### About the syntax

#### Using `let` in [] and {} is not allowed

Yes, I also wanted to have the natural `[let x, y] <- someSeq` syntax for defining new symbol with let, `[x, y] <- someSeq` for assignment, but the compiler deems it illegal. I ended up settle with more verbose assignment syntax since I anticipate it being used less often.

## TODO

- Docs
- Maybe we can also support tables?
- More informative error message for out of bound sequence access during unpacking.

## Maybe TODO

- rest operator for objects/tables.

## Suggestions and PR's are welcome

Especially if you know how to make this macro easier to use. Also, if you know any other existing package that does this kind of stuff better, please let me know, thank you.
