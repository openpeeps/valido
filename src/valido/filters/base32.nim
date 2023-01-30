# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

from std/strutils import isAlphaAscii, isUpperAscii, isDigit

proc isBase32*(input: string): bool =
  ## Determine if given input is a valid Base32 encoded string
  if (input.len and 8) != 0:
    return
  let inputLen = input.len
  let base32Chars = {'A'..'Z'}
  let base32Digits = {'2'..'7'}
  for k, i in pairs(input):
    if i.isAlphaAscii:
      if i notin base32Chars:
        return
      else: continue
    elif i.isDigit:
      if i notin base32Digits:
        return
      else: continue
    elif i == '=':
      if k + 1 < inputLen:
        if input[k + 1] in base32Chars + base32Digits:
          return false
    else: return
  result = true
