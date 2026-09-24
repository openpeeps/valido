# Valido - A library of string validators and sanitizers
# 
# Originally, from
# https://github.com/validatorjs/validator.js/blob/master/src/lib/isBase64.js
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

from std/strutils import find

proc isBase64*(i: string, urlSafe = false): bool =
  ## Check if a string is base64 encoded.
  ## Set `urlSafe` to validate the URL-safe alphabet (`-` and `_`, no padding).
  if urlSafe:
    for c in i:
      if c notin {'A'..'Z', 'a'..'z', '0'..'9', '-', '_'}: return false
    return true
  let ln = i.len
  if ln mod 4 == 0:
    let fpadchar = i.find('=', last = 1)
    return fpadchar == -1 or
           fpadchar == (ln - 1) or
           (fpadchar == ln - 2 and i[ln - 1] == '=')