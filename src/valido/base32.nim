# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase32.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import pkg/openparser/regex

proc isBase32*(input: string): bool =
  ## Check if a string is base32 encoded using the regular expression
  var exp = initRegexVM(compile(r"^[A-Z2-7]+=*$"))
  input.len mod 8 == 0 and exp.match(input).matched