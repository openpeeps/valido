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
        ident "/",
        nnkInfix.newTree(
          ident "/",
          ident  "valido",
          ident "filters"
        ),
        filters
      )
    ),
    exports
  )

importFilters()