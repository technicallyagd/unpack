import macros
import deprecating/oldAPI
export oldAPi

const
  restOp = "*"
  skipOp = "_"

proc getRealDest(dest: NimNode; restCount: var int): NimNode =
  result = dest
  case dest.kind:
  of nnkVarTy:
    result = dest[0]
  of nnkPrefix:
    if dest[0].strVal != restOp:
      error("Only prefix allowed is `" & restOp & "` operator", dest)
    else:
      if restCount > 0:
        error("Only one rest operator allowed per unpack")
      restCount += 1
    result = dest[1]
  else: discard

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
  var
    startInd = 0
    endCount = 0
    restCount = 0
    restDest = newLit(0)
  # First pass from the front
  for dest in dests.children:
    let realDest = getRealDest(dest, restCount)
    var newNode = stNode.copyNimTree
    if realDest.strVal != skipOp:
      if restCount == 0:
        newNode[0] = realDest
        newNode[^1] = nnkBracketExpr.newTree(src, newLit(startInd))
        section.add(newNode)
    if restCount == 0: startInd += 1
    else:
      if restDest.kind == nnkIntLit:
        restDest = realDest
      else: endCount += 1
  # Second pass from the back
  if endCount > 0:
    for endInd in 1..endCount:
      let realDest = getRealDest(dests[^endInd], restCount)
      var newNode = stNode.copyNimTree

      if realDest.strVal != skipOp:
        newNode[0] = realDest
        newNode[^1] = nnkBracketExpr.newTree(src, nnkPrefix.newTree(
          newIdentNode("^"),
          newLit(endInd)
        ))
        section.add(newNode)
  # Adds rest statement
  if restCount == 1:
    var newNode = stNode.copyNimTree
    if restDest.strVal != skipOp:
      newNode[0] = restDest
      newNode[^1] = nnkBracketExpr.newTree(src, nnkInfix.newTree(
        newIdentNode("..^"),
        newLit(startInd),
        newLit(endCount+1)
      ))
      section.add(newNode)


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
  result = unpackObjectInternal(src, dests, nnkStmtList, nnkAsgn)

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
  result = unpackSequenceInternal(src, dests, nnkStmtList, nnkAsgn)

