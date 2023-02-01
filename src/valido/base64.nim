# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase64.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/re
from std/strutils import find

let urlSafeBase64 = re"/^[A-Z0-9_\-]*$/i"

proc isBase64*(i: string, urlSafe = false): bool =
  if urlSafe:
    return i.match(urlSafeBase64)
  let ln = i.len
  if ln mod 4 == 0:
    let fpadchar = i.find('=', last = 1)
    return fpadchar == -1 or
           fpadchar == (ln - 1) or
           (fpadchar == ln - 2 and i[ln - 1] == '=')