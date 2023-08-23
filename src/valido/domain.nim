# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import ./utils/tlds
from std/strutils import toUpperAscii, split, count

const validTLDs = GetTLDs

proc isDomain*(input: string): bool =
  ## Validates a domain name including Top-Level-Domain.
  if input.count(".") != 1:
    return false
  var
    i = 0
    v = input.split(".")
    domainName = v[0]
    tld = v[1]

  let
    hyphenSep = {'-'}
    domainLen = domainName.len

  # a domain name cannot start/end with hyphen
  if input[0] in hyphenSep or input[^1] in hyphenSep: return false 
  # accept only valid Top Level Domains
  if toUpperAscii(tld) notin validTLDs: return false
  result = true