import std/[macros, os, strutils]

when defined napibuild:
  import denim
  import pkg/valido/[base32, base58, base64, domain, email, ean, ip, md5]

  const errident = "Valido"

  init proc(module: Module) =
    module.registerFn(1, "isEmail"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isEmail(args[0].getStr)

    module.registerFn(2, "isIP4"):
      echo args.len
      if Env.expect(args, errident, ("input", napi_string), ("?allowLoopback", napi_boolean)):
        return %* isIP4(args[0].getStr, args[1].getBool)
    
    module.registerFn(1, "isDomain"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isDomain(args[0].getStr)

    module.registerFn(1, "isBase32"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isBase32(args[0].getStr)
    
    module.registerFn(1, "isBase58"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isBase58(args[0].getStr)
    
    module.registerFn(1, "isMD5"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isMD5(args[0].getStr)

    module.registerFn(1, "isEAN13"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isEAN13(args[0].getStr)

    module.registerFn(1, "isEAN8"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isEAN8(args[0].getStr)

    module.registerFn(1, "isEAN"):
      if Env.expect(args, errident, ("input", napi_string)):
        return %* isEAN(args[0].getStr).status
    
else:
  macro importFilters() =
    let filtersPath = currentSourcePath().parentDir / "valido"
    var
      filters = newTree(nnkBracket)
      procs = newTree(nnkStmtList)
      exports = newTree(nnkExportStmt)
    for filter in walkDir(filtersPath):
      if not filter.path.endsWith(".nim"):
        continue
      let filterName = filter.path.extractFilename()[0 .. ^5]
      filters.add ident filterName
      exports.add ident filterName
    result = newStmtList()
    result.add(
      nnkImportStmt.newTree(
        nnkInfix.newTree(
          ident "/",
          ident  "valido",
          filters
        )
      ),
      exports
    )

  importFilters()