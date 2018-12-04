# Module Unpack

Array/Sequence/Object destructuring/unpacking macros attempt to quench the thirst of (Python, ES6, et al.)-spoiled people.

Inspired by @Yardanico's [unpackarray.nim](https://gist.github.com/Yardanico/b6fee43f6da8a3bbf0fe048063357115)

## Example Usage

```nim

let someSeq = @[1, 1, 2, 3, 5]
someSeq.lunpack(a,b,c) # creates a, b, c with 'let'
echo a, b, c # 112
someSeq.vunpack(d,e) # creates d,e with 'var'
someSeq.unpack(a,c) # assigns someSeq[0] to a, someSeq[1] to c

type
  Person = object
    name, job: string

let tim = Person(name: "Tim", job: "Fluffer")

tim.lunpack(name, job) # creates name, job with let and assign respective member values to them

tim.lunpack(job, name = otherName) # you can also unpack into custom names using '='

# will not invoke proc chain multiple times
tim.someProcWithSideEffects(arg).lunpack(name, job)

# is expanded into:
# let someUniqueSym1212498 = tim.someProcWithSideEffects(arg)
# let
#   name = someUniqueSym1212498.name
#   job = someUniqueSym1212498.job
```

## TODO

- Docs
- Support arbitrary entity with `[]` defined to use as index
- Maybe we can also support tables?

## Suggestions and PR's are welcome

Especially if you know how to make this macro easier to use. Also, if you know any other existing package that does this kind of stuff better, please let me know, thank you.
