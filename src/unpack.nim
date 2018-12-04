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
        newNode[0] = dest[1]
        newNode[^1] = nnkDotExpr.newTree(src, dest[0])
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

