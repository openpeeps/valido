import std/[macros, os, strutils]

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