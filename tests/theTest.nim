import unittest

import unpack

suite "Sequence-like unpacking with unpackSeq/aUnpackSeq macro":
  setup:
    let testSeq = @[2, 4, 6]
    let testArray = [2, 4, 6]
    let testTuple = (2, 4, 6)
    let testString = "246"

  test "should unpack sequence":
    testSeq.unpackSeq(a, b, c)
    check [a, c, b] == [2, 6, 4]
    # is expanded into:
    # let
    #   a = testSeq[0]
    #   b = testSeq[1]
    #   c = testSeq[2]

  test "should ignore '_' in sequence":
    testSeq.unpackSeq(a, _, c)
    check [a, c] == [2, 6]
    # is expanded into:
    # let
    #   a = testSeq[0]
    #   c = testSeq[2]

  test "should unpack array":
    testArray.unpackSeq(a, b, c)
    check [a, c, b] == [2, 6, 4]

  test "should unpack tuple":
    testTuple.unpackSeq(a, b, c)
    check [a, c, b] == [2, 6, 4]
    ## testTuple.unpackObject(d, e, f, g) <- will cause IndexError at runtime

  test "should unpack string":
    testString.unpackSeq(a, b, c)
    check [a, c, b] == ['2', '6', '4']

  test "should unpack from index 0 to arbitrary number":
    testTuple.unpackSeq(a, b)
    check [a, b] == [2, 4]

  test "unpackSeq with var before first item should create variables with var":
    testTuple.unpackSeq(var a, b)
    check [a, b] == [2, 4]
    a = 13
    check a == 13

  test "unpackSeq without var before first item defines symbols with let":
    testTuple.unpackSeq(a, b)
    check [a, b] == [2, 4]

  test "aUnpackSeq should assign data to existing variables":
    var a, b = 1
    testTuple.aUnpackSeq(a, _, b)
    check [a, b] == [2, 6]

suite "Sequence unpacking with arrow operators":
  setup:
    let testSeq = @[2, 4, 6]
    let testArray = [2, 4, 6]
    let testTuple = (2, 4, 6)

  test "should unpack sequence":
    [a, b, c] <- testSeq
    check [a, c, b] == [2, 6, 4]
    # is expanded into:
    # let
    #   a = testSeq[0]
    #   b = testSeq[1]
    #   c = testSeq[2]
  test "should unpack array":
    [a, b, c] <- testArray
    check [a, c, b] == [2, 6, 4]
  test "should unpack tuple":
    [a, b, c] <- testTuple
    check [a, c, b] == [2, 6, 4]
    ## [d, e, f, g] <- testTuple <- will cause IndexError at runtime
  test "should unpack from index 0 to arbitrary number":
    [a, b] <- testTuple
    check [a, b] == [2, 4]
  test "adding var before first item should create mutable variables":
    [var a, b] <- testTuple
    check [a, b] == [2, 4]
    a = 13
    check a == 13
  test "<- without var defines symbols with let":
    [a, b] <- testTuple
    check [a, b] == [2, 4]
  test "<-- should assign data to existing variables":
    var a, b = 1
    [a, b] <-- testTuple
    check [a, b] == [2, 4]

suite "Object meber unpacking unpackObject/aUnpackObject":
  type
    Person = object
      name, job: string
    PersonRef = ref Person
  setup:
    let timName = "Tim"
    let fluffer = "Fluffer"
    let johnName = "John"
    let tim = Person(name: timName, job: fluffer)
    let timRef = new(Person)
    timRef.name = timName
    timRef.job = fluffer
    var secreteCounter = 0
    proc colleague(p: Person; name: string): Person =
      secreteCounter += 1
      result = p
      result.name = name
  test "should unpack ordinary objects":
    tim.unpackObject(name, job)
    check name == timName
    check job == fluffer

  test "should unpack object refs":
    timRef.unpackObject(name, job)
    check name == timName
    check job == fluffer

  test "should unpack object pointers":
    let timPtr = unsafeAddr(tim)
    timPtr.unpackObject(job, name)
    check name == timName
    check job == fluffer

  test "should not call proc multiple times when invoked after a chain of calls":
    tim.colleague(johnName).unpackObject(name, job)

    # is expanded into:
    # let someUniqueSym1_212_498 = tim.colleague(johnName)
    # let
    #   name = someUniqueSym1_212_498.name
    #   job = someUniqueSym1_212_498.job

    check name == johnName
    check job == fluffer
    check secreteCounter == 1

  test "should be able to rename object member with '=' sign":
    tim.unpackObject(name = otherName)

    check otherName == timName

    tim.unpackObject(job, name = yetAnotherName) # and is order-agnostic.

    check yetAnotherName == timName
    check job == fluffer

  test "adding var before first item should create new variables":
    tim.unpackObject(var name = otherName, job)

    check otherName == timName
    check job == fluffer
    otherName = johnName

    check otherName == johnName

  test "aUnpackObject should assign to existing variables":
    var otherName, yetAnotherName, job = ""
    tim.aUnpackObject(name = otherName)

    check otherName == timName

    tim.aUnpackObject(job, name = yetAnotherName) # and is order-agnostic.

    check yetAnotherName == timName
    check job == fluffer

suite "Object meber unpacking with arrow operators":
  type
    Person = object
      name, job: string
    PersonRef = ref Person
  setup:
    let timName = "Tim"
    let fluffer = "Fluffer"
    let johnName = "John"
    let poofer = "Poofer"
    let tim = Person(name: timName, job: fluffer)
    let timRef = new(Person)
    timRef.name = timName
    timRef.job = fluffer
    var secreteCounter = 0
    proc colleague(p: Person; name: string): Person =
      secreteCounter += 1
      result = p
      result.name = name
  test "should unpack ordinary objects":
    {name, job} <- tim
    check name == timName
    check job == fluffer

  test "should unpack object refs":
    {name, job} <- timRef
    check name == timName
    check job == fluffer

  test "should unpack object pointers":
    let timPtr = unsafeAddr(tim)
    {job, name} <- timPtr
    check name == timName
    check job == fluffer

  test "should not call proc multiple times when invoked after a chain of calls":
    {name, job} <- tim.colleague(johnName)

    # is expanded into:
    # let someUniqueSym1_212_498 = tim.colleague(johnName)
    # let
    #   name = someUniqueSym1_212_498.name
    #   job = someUniqueSym1_212_498.job

    check name == johnName
    check job == fluffer
    check secreteCounter == 1

  test "should be able to rename object member with ':' sign":
    {name: otherName} <- tim

    check otherName == timName

    {job, name: yetAnotherName} <- tim # and is order-agnostic.

    check yetAnotherName == timName
    check job == fluffer
  test "adding var before first item should create all symbol as mutable variables":
    {var name: otherName, job} <- tim

    check otherName == timName
    check job == fluffer

    job = poofer
    otherName = johnName

    check job == poofer
    check otherName == johnName
  test "<-- should assign data to existing variables":
    {var name, job} <- tim

    check name == timName
    check job == fluffer

    {name, job} <-- tim.colleague(johnName)

    check name == johnName

suite "Named tuple unpacking with arrow operators":
  setup:
    type
      Animal = tuple[numLegs: int; name, genus: string]
    let carolyn = "Carolyn"
    let felis = "Felis"
    let equus = "Equus"
    let bojack = "BoJack"
    let cat = (numLegs: 2, name: carolyn, genus: felis).Animal
    let horse = (numLegs: 2, name: bojack, genus: equus).Animal
  test "should be unpackable with [] like unpacking sequences":
    [var l, n, g] <- cat
    check (l, n, g) == (2, carolyn, felis)
    [l, n] <-- horse
    check (l, n, g) == (2, bojack, felis)
    [_, _, g] <-- horse
    check (l, n, g) == (2, bojack, equus)

  test "should be unpackable with {} like unpacking objects":
    {var numLegs: l, name: n, genus: g} <- cat
    check (l, n, g) == (2, carolyn, felis)
    {name: n, numLegs: l} <-- horse
    check (l, n, g) == (2, bojack, felis)
    {genus: g} <-- horse
    check (l, n, g) == (2, bojack, equus)
