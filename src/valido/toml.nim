# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import pkg/openparser/toml
from std/strutils import strip

proc isToml*(input: string): bool =
  ## Determine if given input is valid TOML.
  if input.strip.len == 0: return false
  try:
    discard parseTOML(input)
    result = true
  except OpenParserTomlError: discard
  except: discard
