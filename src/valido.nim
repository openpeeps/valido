import std/[macros, os, strutils]

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
        newIdentNode("/"),
        nnkInfix.newTree(
          newIdentNode("/"),
          newIdentNode("valido"),
          newIdentNode("filters")
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
