# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import tables, strutils, bigints

# https://bank.codes/iban/examples/
let ibanLen = toTable({
  # European Countries
  "AX": 18, "AL": 28, "AD": 24, "AT": 20, "BY": 28, "BE": 16, "BA": 20, "BG": 22,
  "HR": 21, "CY": 28, "CZ": 24, "DK": 18, "EE": 20, "FO": 18, "FI": 18, "FR": 27,
  "DE": 22, "GI": 23, "GR": 27, "GL": 18, "HU": 28, "IS": 26, "IE": 22, "IT": 27,
  "XK": 20, "LV": 21, "LI": 21, "LU": 20, "MK": 19, "MT": 31, "MD": 24, "MC": 27,
  "ME": 22, "NL": 18, "NO": 15, "PL": 28, "PT": 25, "RO": 24, "SM": 27, "RS": 22,
  "SK": 24, "SI": 19, "ES": 24, "SE": 24, "CH": 21, "GB": 22,
  # NON-European Countries
  "AZ": 28, "BH": 22, "BR": 29, "VG": 24, "CR": 21, "DO": 28, "SV": 28, "GF": 27,
  "PF": 27, "TF": 27, "GE": 22, "GP": 27, "GU": 28, "IR": 26, "IQ": 23, "IL": 23,
  "JO": 30, "KZ": 20, "KW": 30, "LB": 28, "MQ": 27, "MR": 27, "MU": 30, "YT": 27,
  "NC": 27, "PK": 24, "PS": 29, "QA": 29, "RE": 27, "BL": 27, "LC": 32, "MF": 27,
  "PM": 27, "ST": 25, "SA": 24, "TL": 23, "TN": 24, "TR": 26, "UA": 29, "AE": 23,
  "WF": 27
  })
 
proc isIBAN*(iban: string): bool =
  var iban = iban.replace(" ","").replace("\t","")
  if iban.len != ibanLen[iban[0..1]]:
    return false
  iban = iban[4..iban.high] & iban[0..3]
  var digits = ""
  for ch in iban:
    case ch
      of '0'..'9': digits.add($(ch.ord - '0'.ord))
      of 'A'..'Z': digits.add($(ch.ord - 'A'.ord + 10))
      else: discard
  result = initBigInt(digits) mod initBigInt(97) == initBigInt(1)
 
# for account in ["GB82 WEST 1234 5698 7654 32", "GB82 TEST 1234 5698 7654 32"]:
#     echo account, " validation is: ", validIban account