import macros

proc unpackInternal(srcNode, dests: NimNode; sec,
  statement: NimNodeKind): NimNode =
  result = newStmtList()
  var section = sec.newTree()
  var stNode = statement.newTree(newEmptyNode(), newEmptyNode())
  if statement != nnkAsgn:
    stNode.add(newEmptyNode())
  var src = srcNode
  # Creates a temporary symbol to store proc result.
  if src.kind != nnkSym:
    src = genSym(nskLet, "src")
    result.add(newLetStmt(src, srcNode))
  let typ = srcNode.getType
  case typ.typeKind:
  of ntySequence, ntyArray, ntyOpenArray, ntyTuple:
    var i = 1
    for dest in dests.children:
      if dest.strVal != "_":
        var newNode = stNode.copyNimTree
        newNode[0] = dest
        newNode[^1] = nnkBracketExpr.newTree(src, newLit(i-1))
        section.add(newNode)
      inc i
  of ntyObject, ntyRef, ntyPtr:
    for dest in dests.children:
      case dest.kind:
      of nnkExprEqExpr:
        var newNode = stNode.copyNimTree
        newNode[0] = dest[0]
        newNode[^1] = nnkDotExpr.newTree(src, dest[1])
        section.add(newNode)
      else:
        var newNode = stNode.copyNimTree
        newNode[0] = dest
        newNode[^1] = nnkDotExpr.newTree(src, dest)
        section.add(newNode)
  else: error("Oh NOOoo! Type `" & $src.typeKind & "` can not be unpacked!",
      src)
  result.add(section)

macro vunpack*(src: typed; dests: varargs[untyped]): typed {.
  deprecated: "use unpackObject/unpackSeq instead".} =
  unpackInternal(src, dests, nnkVarSection, nnkIdentDefs)
macro lunpack*(src: typed; dests: varargs[untyped]): typed {.
  deprecated: "use unpackObject/unpackSeq instead".} =
  unpackInternal(src, dests, nnkLetSection, nnkIdentDefs)
macro unpack*(src: typed; dests: varargs[untyped]): typed {.
  deprecated: "use aUnpackObject/aunpackSeq instead".} =
  unpackInternal(src, dests, nnkStmtList, nnkAsgn)

proc unpackSequenceInternal(srcNode, dests: NimNode; sec,
  statement: NimNodeKind): NimNode =
  result = newStmtList()
  var section = sec.newTree()
  var stNode = statement.newTree(newEmptyNode(), newEmptyNode())
  if statement != nnkAsgn:
    stNode.add(newEmptyNode())
  var src = srcNode
  # Creates a temporary symbol to store proc result.
  if src.kind != nnkSym:
    src = genSym(nskLet, "src")
    result.add(newLetStmt(src, srcNode))
  var i = 1
  for dest in dests.children:
    var newNode = stNode.copyNimTree
    var realDest = dest
    case dest.kind:
    of nnkVarTy:
      realDest = dest[0]
    else: discard
    if realDest.strVal != "_":
      newNode[0] = realDest
      newNode[^1] = nnkBracketExpr.newTree(src, newLit(i-1))
      section.add(newNode)
    inc i

  result.add(section)

proc unpackObjectInternal(srcNode, dests: NimNode; sec,
  statement: NimNodeKind): NimNode =
  result = newStmtList()
  var section = sec.newTree()
  var stNode = statement.newTree(newEmptyNode(), newEmptyNode())
  if statement != nnkAsgn:
    stNode.add(newEmptyNode())
  var src = srcNode
  # Creates a temporary symbol to store proc result.
  if src.kind != nnkSym:
    ## echo src.treeRepr
    src = genSym(nskLet, "src")
    result.add(newLetStmt(src, srcNode))
  for dest in dests.children:
    case dest.kind:
    of nnkExprColonExpr, nnkExprEqExpr:
      var realDest = dest[0]
      case realDest.kind:
      of nnkVarTy:
        realDest = realDest[0]
      else: discard
      var newNode = stNode.copyNimTree
      newNode[0] = dest[1]
      newNode[^1] = nnkDotExpr.newTree(src, realDest)
      section.add(newNode)
    else:
      var realDest = dest
      case dest.kind:
      of nnkVarTy:
        realDest = dest[0]
      else: discard
      var newNode = stNode.copyNimTree
      newNode[0] = realDest
      newNode[^1] = nnkDotExpr.newTree(src, realDest)
      section.add(newNode)

  result.add(section)

macro `<-`*(dests: untyped; src: typed): typed =
  ## Creates new symbol to unpack src into
  ## [a, b, c] <- src
  ## put var before first item to create mutable variable
  ## [var a, b, c] <- src
  ## unpacking objects
  ## {var meberA, meberB, memberC} <- src
  ## unpacking objects to symbols with custom names
  ## {var meberA : customNameA, meberB, memberC : customNameC} <- src

  var hasVar = false
  var firstDest = dests[0]
  while firstDest.len > 0:
    if firstDest.kind == nnkVarTy:
      hasVar = true
      break
    firstDest = firstDest[0]
  let sec = if hasVar: nnkVarSection else: nnkLetSection
  let statement = nnkIdentDefs
  case dests.kind:
  of nnkBracket:
    result = unpackSequenceInternal(src, dests, sec, statement)
  of nnkCurly, nnkTableConstr:
    result = unpackObjectInternal(src, dests, sec, statement)
  else:
    error("Oh Noo! Unknown kind: " & $dests.kind)

macro `<--`*(dests: untyped; src: typed): typed =
  ## unpack src into existing symbols
  ## [a, b, c] <-- src
  ## for objects
  ## {meberA, meberB, memberC} <-- src
  ## rename
  ## {meberA:customNameA, meberB, memberC} <-- src
  let sec = nnkStmtList
  let statement = nnkAsgn
  case dests.kind:
  of nnkBracket:
    result = unpackSequenceInternal(src, dests, sec, statement)
  of nnkCurly, nnkTableConstr:
    result = unpackObjectInternal(src, dests, sec, statement)
  else:
    error("Oh Noo! Unknown kind: " & $dests.kind)


macro unpackObject*(src: typed; dests: varargs[untyped]): typed =
  ## unpacking objects/named tuples into immutable symbols (i.e. create new symbol with `let`)
  ## src.unpackObject(meberA, meberB, memberC)
  ## unpacking objects into new variables
  ## src.unpackObject(var meberA, meberB, memberC)
  ## unpacking objects to symbols with custom names
  ## src.unpackObject(var memberA = customNameA, meberB, memberC = customNameC)
  var hasVar = false
  var firstDest = dests[0]
  while firstDest.len > 0:
    if firstDest.kind == nnkVarTy:
      hasVar = true
      break
    firstDest = firstDest[0]
  let sec = if hasVar: nnkVarSection else: nnkLetSection
  let statement = nnkIdentDefs
  result = unpackObjectInternal(src, dests, sec, statement)

macro aUnpackObject*(src: typed; dests: varargs[untyped]): typed =
  ## assigning unpacked objects/named tuples members into existing symbols 
  ## var memberA, memberB, memberC: string
  ## src.aUnpackObject(meberA, meberB, memberC)
  ## unpacking objects to symbols with custom names
  ## var customNameA,customNameC:string
  ## src.aUnpackObject(memberA = customNameA, meberB, memberC = customNameC)
  let sec = nnkStmtList
  let statement = nnkAsgn
  result = unpackObjectInternal(src, dests, sec, statement)

macro unpackSeq*(src: typed; dests: varargs[untyped]): typed =
  ## unpacking array/seq/tuple into immutable symbols (i.e. create with `let`)
  ## src.unpackSeq(a, b, c)
  ## unpacking array/seq/tuple into variables
  ## src.unpackSeq(var a, b, c)
  var hasVar = false
  var firstDest = dests[0]
  while firstDest.len > 0:
    if firstDest.kind == nnkVarTy:
      hasVar = true
      break
    firstDest = firstDest[0]
  let sec = if hasVar: nnkVarSection else: nnkLetSection
  let statement = nnkIdentDefs
  result = unpackSequenceInternal(src, dests, sec, statement)

macro aUnpackSeq*(src: typed; dests: varargs[untyped]): typed =
  ## assigning values unpacked from seq/array/tuple into existing symbols 
  ## var a, b, c: int
  ## src.aUnpackSeq(a, b, c)
  let sec = nnkStmtList
  let statement = nnkAsgn
  result = unpackSequenceInternal(src, dests, sec, statement)
