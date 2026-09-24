# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import pkg/openparser/regex
import pkg/openparser/regex/lexer

proc isRegex*(pattern: string): bool =
  ## Determine if given pattern is a valid regular expression
  ## using the openparser regex engine.
  try:
    discard compile(pattern)
    result = true
  except OpenParserRegexError: discard
  except: discard

proc isRegexMatch*(pattern, input: string): bool =
  ## Determine if given input matches the regex pattern (full match).
  try:
    result = match(pattern, input).matched
  except OpenParserRegexError: discard
  except: discard
