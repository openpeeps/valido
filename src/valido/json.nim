# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/json

proc isJSON*(input: string): bool =
  try:
    discard parseJSON(input)
    result = true
  except JsonParsingError,
         ValueError: discard