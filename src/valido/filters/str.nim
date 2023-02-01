# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/[macros, re]
from std/strutils import Whitespace, Letters, Digits,
                        parseFloat, parseInt, parseHexStr

# from std/strutils import Whitespace, Letters, Digits,
#                         LowercaseLetters, UppercaseLetters
const
  UppercaseLetters* = {'A'..'Z'}
  LowercaseLetters* = {'a'..'z'}

proc isLowercase*(input: string, withWhitespaces: bool, withNumbers = false): bool =
  ## Determine if given input is in lowercase. Optionally, you can allow
  ## whitespaces and numbers.
  ## TODO ASCII and Unicode support
  if withWhitespaces and withNumbers:
    for c in input:
      if c notin LowercaseLetters + Whitespace + Digits:
        return
    result = true
  elif withWhitespaces:
    for c in input:
      if c notin LowercaseLetters + Whitespace:
        return
    result = true
  elif withNumbers:
    for c in input:
      if c notin LowercaseLetters + Digits: 
        return
    result = true
  else:
    for c in input:
      if c notin LowercaseLetters:
        return
    result = true

proc isLowercase*(input: string): bool =
  ## Determine if given string input is lowercase
  ## TODO ASCII and Unicode support
  for c in input:
    if c notin LowercaseLetters: return
  result = true

proc isUppercase*(input: string, withWhitespaces, withNumbers = false): bool =
  ## Determine if ginve string input is uppercase
  if withWhitespaces and withNumbers:
    for c in input:
      if c notin UppercaseLetters + Whitespace + Digits:
        return
    result = true
  elif withWhitespaces:
    for c in input:
      if c notin UppercaseLetters + Whitespace:
        return
    result = true
  elif withNumbers:
    for c in input:
      if c notin UppercaseLetters + Digits: 
        return
    result = true
  else:
    for c in input:
      if c notin UppercaseLetters:
        return
    result = true

proc isDigits*(input: string): bool =
  for d in input:
    if d notin Digits: return
  result = true

proc isDigits*(input: string, sep: char): bool =
  ## Check if given input contains digits. Allows a separator
  for d in input:
    if d notin Digits + {sep}: return
  result = true

proc isAlpha*(input: string, withWhitespaces = false, ws = Whitespace): bool =
  ## Checks whether or not input string is alphabetical 
  if withWhitespaces:
    for c in input:
      if c notin Letters + ws: return
    return true
  for c in input:
    if c notin Letters: return
  result = true

proc isAlphaNumeric*(input: string, withWhitespaces = false, ws = Whitespace): bool =
  if withWhitespaces:
    for c in input:
      if c notin Letters + Digits + ws: return
    return true
  for c in input:
    if c notin Letters + Digits: return
  result = true

proc isBoolean*(input: string): bool =
  ## Determine if given input is a boolean
  result = input in ["true", "false"]

proc isFloat*(input: string): bool =
  ## Determine if given input is a float number
  try:
    discard parseFloat(input)
    result = true
  except ValueError: discard

proc isHexStr*(input: string): bool =
  ## Determine if given input is a hex 
  try:
    discard parseHexStr(input)
    result = true
  except ValueError: discard

proc isRegex*(input: string): bool = 
  try:
    discard re(input)
    result = true
  except RegexError: discard