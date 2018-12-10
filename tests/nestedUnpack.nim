import unittest

import unpack
import macros

type
  Person = object
    name, job: string
    hobby: seq[string]
let testSeq = @[@[2, 4], @[6, 4], @[3, 4, 5]]
let testTuple = ((2, 4), 6, ((3, 4), 5))
let timName = "Tim"
let johnName = "John"
let fluffer = "Fluffer"
let bobber = "Bobber"
let waterBottle = "water bottle"
let timHobby = @[waterBottle, "stapler"]
let people = [Person(name: timName, job: fluffer, hobby: timHobby),
    Person(name: johnName, job: bobber)]

suite "Unpacking nested sequence":
  test "should unpack nested sequence":
    testSeq.unpackSeq([a, b], [c])
    check [a, c, b] == [2, 6, 4]
    # is expanded into:
    # let
    #   a = testSeq[0][0]
    #   b = testSeq[0][1]
    #   c = testSeq[1][0]
  test "should unpack nested tuples":
    testTuple.unpackSeq([a, b], c, [_, d])
    check [a, c, b, d] == [2, 6, 4, 5]

  test "should unpack nested sequence of objects with sequences":
    people.unpackSeq({name, job, hobby as [a, _]}, john)
    # expands into:
    # let
    #   name = people[0].name
    #   job = people[0].job
    #   a = people[0].hobby[0]
    #   john = people[1]
    check name == timName
    check job == fluffer
    check a == waterBottle
    check john.name == johnName

  test "<- should also unpack nested sequence of objects with sequences":
    [var {name, job, hobby as [a, _]}, john] <- people
    # expands into:
    # var
    #   name = people[0].name
    #   job = people[0].job
    #   a = people[0].hobby[0]
    #   john = people[1]
    check name == timName
    check job == fluffer
    check a == waterBottle
    check john.name == johnName
    job = bobber
    check job == bobber


type
  Cult = object
    members: array[2, Person]
    name: string
let
  tinyCult = "tinyCult"
  theCult = Cult(members: people, name: tinyCult)

suite "Unpacking nested objects":

  test "should also unpack nested objects":
    {members as [_, john], name} <- theCult
    check john.name == johnName
    check name == tinyCult
  test "should work with variables definition":
    {var members as [_, john], name} <- theCult
    check john.name == johnName
    check name == tinyCult

    john.name = timName
    check john.name == timName

  test "should work with reassignment as well":

    {var members as [_, john], name} <- theCult
    check john.name == johnName
    check name == tinyCult

    {members as [{name}, _]} <-- theCult
    check name == timName
