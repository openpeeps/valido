# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/re
import std/strformat

proc isIP4*(input: string): bool =
  let v4Segment = "(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])"
  let v4Address = "(" & v4Segment & "[.]){3}" & v4Segment
  result = re.match(input, re("^" & v4Address & "$"))

# proc isIP6*(input: string): bool =
#   {.warning: "work in progress".}
#   discard
