# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase32.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/re

let exp = re"^[A-Z2-7]+=*$"

proc isBase32*(input: string): bool =
  input.len mod 8 == 0 and input.match(exp)