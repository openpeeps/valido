# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase58.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import pkg/openparser/regex

proc isBase58*(input: string): bool =
  ## Check if a string is base58 encoded using the regular expression
  var exp = initRegexVM(compile(r"^[A-HJ-NP-Za-km-z1-9]*$"))
  exp.match(input).matched