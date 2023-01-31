# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase58.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/re

let exp = re"^[A-HJ-NP-Za-km-z1-9]*$"

proc isBase58*(input: string): bool =
  input.match(exp)