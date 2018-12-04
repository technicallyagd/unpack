import macros

proc unpackInternal(srcNode,args:NimNode;sec,statement:NimNodeKind): NimNode = 
  result = newStmtList()
  var section = sec.newTree()
  var stNode = statement.newTree(newEmptyNode(),newEmptyNode())
  if statement != nnkAsgn:
    stNode.add(newEmptyNode())
  var src = srcNode
  if src.kind != nnkSym:
    src = genSym(nskLet,"src")
    result.add(newLetStmt(src,srcNode))
  let typ = srcNode.getType
  case typ.typeKind:
  of ntySequence,ntyArray,ntyOpenArray:
    var i = 1
    for arg in args.children:
      var newNode = stNode.copyNimTree
      newNode[0] = arg
      newNode[^1] = nnkBracketExpr.newTree(src,newLit(i-1))
      section.add(newNode)
      inc i
  of ntyObject,ntyRef,ntyPtr:
    for arg in args.children:
      case arg.kind:
      of nnkExprEqExpr:
        var newNode = stNode.copyNimTree
        newNode[0] = arg[1]
        newNode[^1] = nnkDotExpr.newTree(src,arg[0])
        section.add(newNode)
      else:
        var newNode = stNode.copyNimTree
        newNode[0] = arg
        newNode[^1] = nnkDotExpr.newTree(src,arg)
        section.add(newNode)
  else: error("Oh NOOoo! Type `" & $src.typeKind & "` can not be unpacked!",src)
  result.add(section)

macro vunpack*(src:typed;args: varargs[untyped]): typed =
  unpackInternal(src,args,nnkVarSection,nnkIdentDefs)
macro lunpack*(src:typed; args: varargs[untyped]): typed =
  unpackInternal(src,args,nnkLetSection,nnkIdentDefs)
macro unpack*(src:typed; args: varargs[typed]): typed =
  unpackInternal(src,args,nnkStmtList,nnkAsgn)


when isMainModule:
  let lol = @[1,2,3]
  var g,q:int
  lol.unpack(g,q)
  echo g,q
  type
    Person = object
      name,job:string
  proc collegue(p:Person;name:string):Person =  
    result = p
    result.name = name
  let tim = Person(name:"Tim",job:"Fluffer")
  tim.vunpack(name,job)
  echo name
  echo job
  echo "===New Guy==="
  tim.collegue("John").unpack(name,job)
  echo name
  echo job
