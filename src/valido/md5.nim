# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido
import std/strutils

proc isMD5*(input: string): bool =
  ## Checks if given input is a valid MD5 hash
  if input.len != 32: return
  for c in input:
    if c notin {'a'..'f'} and c notin Digits:
      return false
  result = true