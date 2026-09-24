# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import std/tables
import pkg/openparser/colors
from std/strutils import strip, toLowerAscii, startsWith

proc funcName(s: string): string =
  let idx = s.find('(')
  if idx < 0: return ""
  s[0 ..< idx].strip().toLowerAscii()

proc tryParse(s: string): tuple[ok: bool, fname: string] =
  let input = s.strip()
  if input.len == 0: return (false, "")
  try:
    discard parseColor(input)
    (true, funcName(input.toLowerAscii()))
  except ParserColorError: (false, "")
  except: (false, "")

proc isColor*(input: string): bool =
  ## Determine if given input is any valid CSS Color 4 color
  ## (hex, named, rgb/a, hsl/a, hsv, hwb, cmyk, lab, lch, oklab, oklch, transparent).
  isValidColor(input.strip())

proc isHexColor*(input: string): bool =
  ## Hex color with optional leading `#`: 3, 4, 6 or 8 digits.
  let s = input.strip()
  if s.len == 0: return false
  try:
    discard parseHexColor(s)
    result = true
  except ParserColorError: discard
  except: discard

proc isHex*(input: string): bool {.inline.} =
  ## Alias of isHexColor.
  isHexColor(input)

proc isRgb*(input: string): bool =
  ## `rgb(...)` without alpha.
  let (ok, fname) = tryParse(input)
  if not ok or fname != "rgb": return false
  try:
    result = parseColor(input.strip()).a >= 1.0 - 1e-9
  except: discard

proc isRgba*(input: string): bool =
  ## `rgba(...)` or `rgb(...)` with alpha (`/ alpha` or 4th component).
  let (ok, fname) = tryParse(input)
  if not ok or fname notin ["rgb", "rgba"]: return false
  # must spell rgba OR carry transparency
  if fname == "rgba": return true
  try:
    result = parseColor(input.strip()).a < 1.0 - 1e-9
  except: discard

proc isHsl*(input: string): bool =
  ## `hsl(...)` without alpha.
  let (ok, fname) = tryParse(input)
  if not ok or fname != "hsl": return false
  try:
    result = parseColor(input.strip()).a >= 1.0 - 1e-9
  except: discard

proc isHsla*(input: string): bool =
  ## `hsla(...)` or `hsl(...)` with alpha.
  let (ok, fname) = tryParse(input)
  if not ok or fname notin ["hsl", "hsla"]: return false
  if fname == "hsla": return true
  try:
    result = parseColor(input.strip()).a < 1.0 - 1e-9
  except: discard

proc isHsv*(input: string): bool =
  ## `hsv(...)` / `hsb(...)` (alpha allowed, use parse check only).
  let (ok, fname) = tryParse(input)
  result = ok and fname in ["hsv", "hsva", "hsb", "hsba"]

proc isHwb*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname == "hwb"

proc isCmyk*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname in ["cmyk", "device-cmyk"]

proc isLab*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname == "lab"

proc isLch*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname == "lch"

proc isOklab*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname == "oklab"

proc isOklch*(input: string): bool =
  let (ok, fname) = tryParse(input)
  result = ok and fname == "oklch"

proc isNamedColor*(input: string): bool =
  ## CSS named color (case-insensitive, 148 names).
  let s = input.strip().toLowerAscii()
  if s.len == 0: return false
  initNamedTable()
  result = namedTable.hasKey(s)

proc isTransparent*(input: string): bool =
  ## The `transparent` keyword.
  result = input.strip().toLowerAscii() == "transparent"
