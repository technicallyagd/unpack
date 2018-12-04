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

macro vunpack*(src: typed; dests: varargs[untyped]): typed =
  unpackInternal(src, dests, nnkVarSection, nnkIdentDefs)
macro lunpack*(src: typed; dests: varargs[untyped]): typed =
  unpackInternal(src, dests, nnkLetSection, nnkIdentDefs)
macro unpack*(src: typed; dests: varargs[typed]): typed =
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
    newNode[0] = dest
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
    src = genSym(nskLet, "src")
    result.add(newLetStmt(src, srcNode))
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

  result.add(section)

macro `<-`*(dest:untyped;src:typed):typed = 
  ## Creates new symbol to unpack src into
  ## [a, b, c] <- src
  ## put var before first item to create mutable variable
  ## [var a, b, c] <- src
  let hasVar = not findChild(dest[0],it.kind == nnkVarTy).isNil
  let sec = if hasVar:nnkVarSection else: nnkLetSection
  let statement = nnkIdentDefs
  case dest.kind:
  of nnkBracket:
    result = unpackSequenceInternal(src,dest,sec,statement)
  of nnkCurly,nnkTableConstr:
    result = unpackObjectInternal(src,dest,sec,statement)
  else: 
    error("Oh Noo! Unknown kind: " & $dest.kind)

macro `<--`*(dest:typed;src:typed):typed = 
  ## unpack src into existing symbols
  ## [a, b, c] <-- src
  let sec = nnkStmtList
  let statement = nnkAsgn
  case dest.kind:
  of nnkBracket:
    result = unpackSequenceInternal(src,dest,sec,statement)
  of nnkCurly,nnkTableConstr:
    result = unpackObjectInternal(src,dest,sec,statement)
  else: 
    error("Oh Noo! Unknown kind: " & $dest.kind)