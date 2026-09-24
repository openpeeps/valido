# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import pkg/openparser/uuid
from std/strutils import strip, count

export UuidError

type
  UUIDVersion* = enum
    Any, V1, V2, V3, V4, V5, V6, V7, V8

proc hasDashes(s: string): bool =
  s.count("-") == 4

proc isUUID*(input: string, version: UUIDVersion = Any, strictDashes = false): bool =
  ## Validate given input string as UUID (versions 1-8).
  ## Accepts dashed `8-4-4-4-12` and dashless 32-hex forms via openparser.
  ## Set `strictDashes = true` to require the dashed form (legacy valido behavior).
  let s = input.strip()
  if s.len == 0: return false
  if strictDashes and not hasDashes(s): return false
  try:
    let u = parseUuid(s)
    case version
    of Any: result = true
    of V1: result = u.version == 1
    of V2: result = u.version == 2
    of V3: result = u.version == 3
    of V4: result = u.version == 4
    of V5: result = u.version == 5
    of V6: result = u.version == 6
    of V7: result = u.version == 7
    of V8: result = u.version == 8
  except UuidError: discard
  except ValueError: discard
  except: discard

proc isNilUUID*(input: string): bool =
  ## Determine if given input is the nil UUID (`00000000-0000-0000-0000-000000000000`).
  let s = input.strip()
  if s.len == 0: return false
  try:
    result = parseUuid(s).isNil()
  except UuidError: discard
  except ValueError: discard
  except: discard
