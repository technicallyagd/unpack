import unittest

import unpack

suite "Sequence unpacking with (l|v)?unpack macro":
  setup:
    let testSeq = @[2, 4, 6]
    let testArray = [2, 4, 6]
    let testTuple = (2, 4, 6)

  test "should unpack sequence":
    testSeq.lunpack(a, b, c)
    check [a, c, b] == [2, 6, 4]
    # is expanded into:
    # let
    #   a = testSeq[0]
    #   b = testSeq[1]
    #   c = testSeq[2]

  test "should unpack array":
    testArray.lunpack(a, b, c)
    check [a, c, b] == [2, 6, 4]
  test "should unpack tuple":
    testTuple.lunpack(a, b, c)
    check [a, c, b] == [2, 6, 4]
    ## testTuple.lunpack(d, e, f, g) <- will cause IndexError at runtime
  test "should unpack from index 0 to arbitrary number":
    testTuple.lunpack(a, b)
    check [a, b] == [2, 4]
  test "vunpack should create variables with var":
    testTuple.vunpack(a, b)
    check [a, b] == [2, 4]
    a = 13
    check a == 13
  test "lunpack defines symbols with let":
    testTuple.lunpack(a, b)
    check [a, b] == [2, 4]
  test "unpack should assign data to existing variables":
    var a, b = 1
    testTuple.unpack(a, b)
    check [a, b] == [2, 4]

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

suite "Object meber unpacking with (l|v)?unpack macro":
  type
    Person = object
      name, job: string
    PersonRef = ref Person
  setup:
    let timName = "Tim"
    let fluffer = "Fluffer"
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
    tim.lunpack(name, job)
    check name == timName
    check job == fluffer

  test "should unpack object refs":
    timRef.lunpack(name, job)
    check name == timName
    check job == fluffer

  test "should unpack object pointers":
    let timPtr = unsafeAddr(tim)
    timPtr.lunpack(job, name)
    check name == timName
    check job == fluffer

  test "should not call proc multiple times when invoked after a chain of calls":
    let johnName = "John"
    tim.colleague(johnName).lunpack(name, job)

    # is expanded into:
    # let someUniqueSym1212498 = tim.colleague(johnName)
    # let
    #   name = someUniqueSym1212498.name
    #   job = someUniqueSym1212498.job

    check name == johnName
    check job == fluffer
    check secreteCounter == 1

  test "should be able to rename object member with '=' sign":
    tim.lunpack(otherName = name)

    check otherName == timName

    tim.lunpack(job, yetAnotherName = name) # and is order-agnostic.

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
    # let someUniqueSym1212498 = tim.colleague(johnName)
    # let
    #   name = someUniqueSym1212498.name
    #   job = someUniqueSym1212498.job

    check name == johnName
    check job == fluffer
    check secreteCounter == 1

  test "should be able to rename object member with ':' sign":
    {name : otherName} <- tim

    check otherName == timName

    {job, name : yetAnotherName} <- tim # and is order-agnostic.

    check yetAnotherName == timName
    check job == fluffer
  test "adding var before first item should create all symbol as mutable variables":
    {var name : otherName, job} <- tim

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
    
    {name,job} <-- tim.colleague(johnName)

    check name == johnName
