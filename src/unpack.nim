import macros

const
  restOp = "*"
  skipOp = "_"
  renameOp = "as"

proc getRealDest(dest: NimNode; restCount: var int): NimNode =
  result = dest

  if dest.kind == nnkInfix:
    if dest[0].strVal == renameOp:
      result = dest[2]
    else:
      error("Only `" & renameOp & "` is allowed as the infix", dest[0])

  case result.kind:
  of nnkVarTy:
    result = dest[0]
  of nnkPrefix:
    if result[0].strVal != restOp:
      error("Beep boop. I don't understand prefix `" & dest[
          0].strVal & "`. Only prefix I know is `" & restOp & "` operator",
              dest)
    else:
      if restCount > 0:
        error("Only one rest operator allowed per unpack")
      restCount += 1
    result = result[1]
  else: discard

proc processSeqUnpack(section, src, dests, stNode: NimNode): NimNode


proc processObjectUnpack(section, src, dests, stNode: NimNode): NimNode =
  result = section
  for dest in dests.children:
    case dest.kind:
    of nnkInfix:
      if dest[0].strVal == renameOp:
        var realDest = dest[1]
        case realDest.kind:
        of nnkVarTy:
          realDest = realDest[0]
        else: discard
        var newNode = stNode.copyNimTree
        var newSource = nnkDotExpr.newTree(src, realDest)
        let newDest = dest[2]
        case newDest.kind:
        of nnkCurly:
          result = processObjectUnpack(result, newSource, newDest, stNode)
        of nnkBracket:
          result = processSeqUnpack(result, newSource, newDest, stNode)
        else:
          newNode[0] = newDest
          newNode[^1] = newSource
          result.add(newNode)
      else:
        error("Only `" & renameOp & "` is allowed as the infix",
            dest[0])
    of nnkExprColonExpr, nnkExprEqExpr:
      var realDest = dest[0]
      case realDest.kind:
      of nnkVarTy:
        realDest = realDest[0]
      else: discard
      var newNode = stNode.copyNimTree
      newNode[0] = dest[1]
      newNode[^1] = nnkDotExpr.newTree(src, realDest)
      warning("This syntax is being deprecated, please use `{" &
          realDest.strVal & " as " & dest[
          1].strVal & "}` instead", dest)
      result.add(newNode)
    else:
      var realDest = dest
      case dest.kind:
      of nnkVarTy:
        realDest = dest[0]
      else: discard
      var newNode = stNode.copyNimTree
      newNode[0] = realDest
      newNode[^1] = nnkDotExpr.newTree(src, realDest)
      result.add(newNode)

proc processSeqUnpack(section, src, dests, stNode: NimNode): NimNode =
  var
    startInd = 0
    endCount = 0
    restCount = 0
    restDest = newLit(0)
  result = section
  # First pass from the front
  for dest in dests.children:
    let realDest = getRealDest(dest, restCount)
    var newNode = stNode.copyNimTree
    let newSource = nnkBracketExpr.newTree(src, newLit(startInd))
    let newDest = realDest
    case realDest.kind:
    of nnkCurly:
      result = processObjectUnpack(result, newSource, newDest, stNode)
    of nnkBracket:
      result = processSeqUnpack(result, newSource, newDest, stNode)
    else:
      if realDest.strVal != skipOp:
        if restCount == 0:

          newNode[0] = realDest
          newNode[^1] = newSource
          result.add(newNode)
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
      let newSource = nnkBracketExpr.newTree(src, nnkPrefix.newTree(
          newIdentNode("^"),
          newLit(endInd)
        ))
      let newDest = realDest
      case realDest.kind:
      of nnkCurly:
        result = processObjectUnpack(result, newSource, newDest, stNode)
      of nnkBracket:
        result = processSeqUnpack(result, newSource, newDest, stNode)
      else:
        if realDest.strVal != skipOp:
          newNode[0] = realDest
          newNode[^1] = newSource
          result.add(newNode)
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
      result.add(newNode)

proc prepareHead(srcNode: NimNode; sec,
  statement: NimNodeKind): (NimNode, NimNode, NimNode, NimNode) =
  var tobeResult = newStmtList()
  var section = sec.newTree()
  var stNode = statement.newTree(newEmptyNode(), newEmptyNode())
  if statement != nnkAsgn:
    stNode.add(newEmptyNode())
  var src = srcNode
  # Creates a temporary symbol to store proc result.
  if src.kind != nnkSym:
    src = genSym(nskLet, "src")
    tobeResult.add(newLetStmt(src, srcNode))
  (tobeResult, section, src, stNode)

proc unpackSequenceInternal(srcNode, dests: NimNode; sec,
  statement: NimNodeKind): NimNode =
  var (tobeResult, section, src, stNode) = prepareHead(srcNode, sec,
      statement)
  result = tobeResult
  section = processSeqUnpack(section, src, dests, stNode)
  result.add(section)

proc unpackObjectInternal(srcNode, dests: NimNode; sec,
  statement: NimNodeKind): NimNode =
  var (tobeResult, section, src, stNode) = prepareHead(srcNode, sec,
    statement)
  result = tobeResult
  section = processObjectUnpack(section, src, dests, stNode)
  result.add(section)

macro `<-`*(dests: untyped; src: typed): typed =
  ## Creates new symbol to unpack src into
  ## [a, b, c] <- src
  ## put var before first item to create mutable variable
  ## [var a, b, c] <- src
  ## unpacking objects
  ## {var meberA, meberB, memberC} <- src
  ## unpacking objects to symbols with custom names
  ## {var meberA as customNameA, meberB, memberC as customNameC} <- src

  var hasVar = false
  var firstDest = dests[0]
  while firstDest.len > 0:
    case firstDest.kind
    of nnkVarTy:
      hasVar = true
      break
    of nnkInfix: firstDest = firstDest[1]
    else: firstDest = firstDest[0]
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
  ## {meberA as customNameA, meberB, memberC} <-- src
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
  ## unpacking objects/named tuples into immutable symbols 
  ## (i.e. create new symbol with `let`)
  ## src.unpackObject(meberA, meberB, memberC)
  ## unpacking objects into new variables
  ## src.unpackObject(var meberA, meberB, memberC)
  ## unpacking objects to symbols with custom names
  ## src.unpackObject(var memberA as customNameA, meberB, memberC as customNameC)
  var hasVar = false
  var firstDest = dests[0]
  while firstDest.len > 0:
    case firstDest.kind
    of nnkVarTy:
      hasVar = true
      break
    of nnkInfix: firstDest = firstDest[1]
    else: firstDest = firstDest[0]
  let sec = if hasVar: nnkVarSection else: nnkLetSection
  let statement = nnkIdentDefs
  result = unpackObjectInternal(src, dests, sec, statement)

macro aUnpackObject*(src: typed; dests: varargs[untyped]): typed =
  ## assigning unpacked objects/named tuples members into existing symbols 
  ## var memberA, memberB, memberC: string
  ## src.aUnpackObject(meberA, meberB, memberC)
  ## unpacking objects to symbols with custom names
  ## var customNameA,customNameC:string
  ## src.aUnpackObject(memberA as customNameA, meberB, memberC as customNameC)
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

macro unpack*(obj: object | ref object | ptr object): untyped =

  let fieldsAsSymbols =
    if obj.getType.kind == nnkBracketExpr:
      toSeq children obj.getType[1].getType.getType[2]
    else:
      toSeq children obj.getType[2]

  getAst unpackObject(obj, fieldsAsSymbols.map s => ident $s)
