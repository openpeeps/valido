import std/[macros, os, strutils]

dumpAstGen:
  import ./valido/filters/[a, b, c]

macro importFilters() =
  let filtersPath = currentSourcePath().parentDir / "valido" / "filters"
  var filters = newTree(nnkBracket)
  var procs = newTree(nnkStmtList)
  var exports = newTree(nnkExportStmt)
  for filter in walkDir(filtersPath):
    let filterName = filter.path.extractFilename()[0 .. ^5]
    filters.add ident filterName
    exports.add ident filterName
  result = newStmtList()
  result.add(
    nnkImportStmt.newTree(
      nnkInfix.newTree(
        ident "/",
        nnkInfix.newTree(
          ident "/",
          nnkPrefix.newTree(
            ident "./",
            ident  "valido",
          ),
          ident "filters"
        ),
        filters
      )
    ),
    exports
  )

importFilters()

proc validate*(i: string): string {.inline.} =
  result = i

when isMainModule:
  # echo validate("ąćęłńóśżź").isPassword()
  let mypass = "21$)($_@S}{a2aXa"
  echo mypass.validate.isPassword
