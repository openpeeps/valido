# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/macros
from std/strutils import isLowerAscii, isUpperAscii, isAlphaAscii,
             isAlphaNumeric, isDigit, startsWith, endsWith

macro checkString(input: untyped, procName: typed): untyped =
  # Macro for checking given string input against multiple procedures
  # from ``std/strutils`` library, producing the following code:
  #   for s in input:
  #       if not s.isLowerAscii: return false
  #       else: result = true
  nnkStmtList.newTree(
    nnkForStmt.newTree(
      newIdentNode("s"),
      newIdentNode(input.strVal),
      nnkStmtList.newTree(
        nnkIfStmt.newTree(
          nnkElifBranch.newTree(
            nnkPrefix.newTree(
              newIdentNode("not"),
              nnkDotExpr.newTree(
                newIdentNode("s"),
                newIdentNode(procName.strVal)
              )
            ),
            nnkStmtList.newTree(
              nnkReturnStmt.newTree(
                newIdentNode("false")
              )
            )
          ),
          nnkElse.newTree(
            nnkStmtList.newTree(
              nnkAsgn.newTree(
                newIdentNode("result"),
                newIdentNode("true")
              )
            )
          )
        )
      )
    )
  )

# proc isBeginingWith*(input, prefix: string): bool =
#     {.warning: "Implementation needed".}
#     ## Determine if given string input starts with provided prefix
#     ## TODO implement varargs and auto mapping to ``checkString``
#     checkString input, startsWith

# proc isEndingWith*(input, suffix: string): bool =
#     {.warning: "Implementation needed".}
#     ## Determine if given string input ends with provided suffix
#     ## TODO implement varargs and auto mapping to ``checkString``
#     checkString input, endsWith

proc isLowercase*(input: string): bool =
  ## Determine if given string input is lowercase
  ## TODO ASCII and Unicode support
  checkString input, isLowerAscii

proc isUppercase*(input: string): bool =
  ## Determine if ginve string input is uppercase
  checkString input, isUpperAscii

proc isAlpha*(input: string): bool =
  ## Determine if ginve string input contains only alpha characters
  checkString input, isAlphaAscii

proc isAlphanumerical*(input: string): bool =
  ## Determine if given string input is alphanumerical
  ## TODO ASCII and Unicode support
  checkString input, isAlphaNumeric

proc isDigits*(input: string): bool =
  ## Determine if given string input contains only digits
  checkString input, isDigit

