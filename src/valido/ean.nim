import std/strutils

type
  EANType* = enum
    InvalidEAN
    EAN8
    EAN12
    EAN13
    EAN14
    EAN18

  EANStatus* = tuple[status: bool, eanType: EANType] 

proc isEAN13*(ea: string): bool =
  if ea.len == 13:
    try:
      var t: int
      let checkdigit = parseInt(ea[0..0])
      for pos, i in ea[1 .. ^1]:
        if pos mod 2 == 0:
          t += parseInt($i) * 3
        else:
          t += parseInt($i)
      let res = t mod 10
      result = ((10 - res) mod 10) == checkdigit
    except ValueError:
      result = false

proc isEAN8*(ea: string): bool =
  if ea.len == 8:
    try:
      var t: int
      let checkdigit = parseInt(ea[^1..^1])
      for i in countdown(ea.high - 1, 0):
        if i mod 2 == 0:
          t += parseInt($ea[i]) * 3
        else:
          t += parseInt($ea[i])
      let res = t mod 10
      result = ((10 - res) mod 10) == checkdigit
    except ValueError:
      result = false

proc isEAN*(ea: string): EANStatus =
  let bclen = len(ea)
  if bclen == 8:
    result.status = isEAN8(ea)
    if result.status:
      result.eanType = EAN8
  elif bclen == 13:
    result.status = isEAN13(ea)
    if result.status:
      result.eanType = EAN13