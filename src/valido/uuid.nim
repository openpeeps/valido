# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/strutils

type
  UUIDVersion* = enum
    Any, V1, V3, V4, V5

proc isUUID*(input: string, version: UUIDVersion = Any): bool =
  ## Validate given input string as UUID
  ## https://en.wikipedia.org/wiki/Universally_unique_identifier
  if input.count("-") != 4: return false
  let v = input.toLowerAscii.split("-")
  if v.len != 5: return
  var
    timeLow = v[0]
    timeMid = v[1]
    timeHigh = v[2]
    clockSeq = v[3]
    node = v[4]

  if timeLow.len != 8 or timeMid.len != 4 or timeHigh.len != 4 or
     clockSeq.len != 4 or node.len != 12: return false
  
  case version:
    of V1:
      if timeHigh[0] != '1': return false
    of V3:
      if timeHigh[0] != '3': return false
    of V4:
      if timeHigh[0] != '4': return false
    of V5:
      if timeHigh[0] != '5': return false
    else: discard

  var alphaRange = {'a'..'f'}
  for column in [timeLow, timeMid, timeHigh, clockSeq, node]:
    for ichar in column:
      if ichar.isAlphaAscii:
        if ichar notin alphaRange:
          return false
      else:
        if ichar notin Digits: return false

  result = true