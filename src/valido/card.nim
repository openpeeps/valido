# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

from std/strutils import parseInt, multiReplace

proc checkLuhn(cc: string): bool =
  const m = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]
  var
    t = 0
    odd = true
  for i in countdown(cc.high, 0):
    let digit = ord(cc[i]) - ord('0')
    if digit notin 0..9: return false
    t += (if odd: digit else: m[digit])
    odd = not odd
  result = t mod 10 == 0

proc isCard*(input: string): bool = checkLuhn(input)

proc isVisa*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin [13, 16, 19]: return
  if isCard(cc):
    result = cc[0] == '4'

proc isMasterCard*(input: string): bool =
  ## Mastercard BIN ranges: 222100–272099 and 510000–559999
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len != 16: return
  if isCard(cc):
    let firstSix = parseInt(cc[0..5])
    result = firstSix in 222100..272099 or firstSix in 510000..559999

proc isMaestro*(input: string): bool =
  ## Maestro prefixes: 5018, 5020, 5038, 5893, 6304, 6759, 6761, 6762, 6763
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin 12..19: return
  if isCard(cc):
    let prefix4 = parseInt(cc[0..3])
    result = prefix4 in [5018, 5020, 5038, 5893, 6304, 6759, 6761, 6762, 6763]

proc isAmericanExpress*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len != 15: return
  if isCard(cc):
    result = cc[0..1] in ["34", "37"]

proc isAMEX*(input: string): bool =
  ## An alias of `isAmericanExpress`
  result = isAmericanExpress(input)

proc isDiscover*(input: string): bool =
  ## Discover BIN ranges: 6011, 622126–622925, 644–649, 65
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin [16, 19]: return
  if isCard(cc):
    if parseInt(cc[0..1]) == 65:
      result = true
    elif parseInt(cc[0..3]) == 6011:
      result = true
    elif parseInt(cc[0..3]) in 6440..6499:
      result = true
    elif parseInt(cc[0..5]) in 622126..622925:
      result = true

proc isJCB*(input: string): bool =
  ## JCB BIN range: 352800–358999, length 16–19
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin 16..19: return
  if isCard(cc):
    result = parseInt(cc[0..3]) in 3528..3589

proc isDinersClub*(input: string): bool =
  ## Diners Club Carte Blanche/International: 300–305, 36, 38; length 14
  ## Diners Club North America: 54–55; length 16
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if isCard(cc):
    if cc.len == 14:
      let prefix3 = parseInt(cc[0..2])
      result = prefix3 in 300..305 or cc[0..1] in ["36", "38"]
    elif cc.len == 16:
      result = cc[0..1] in ["54", "55"]

proc isMir*(input: string): bool =
  ## Mir payment system: BIN range 2200–2204, length 16–19
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin 16..19: return
  if isCard(cc):
    result = parseInt(cc[0..3]) in 2200..2204

proc isChinaUnionPay*(input: string): bool =
  ## UnionPay BIN ranges: 6220–6229 (primary), also 624–626, 6282–6288
  ## Length: 16–19
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin 16..19: return
  # UnionPay does not mandate Luhn, but we check structure
  let prefix4 = parseInt(cc[0..3])
  let prefix3 = parseInt(cc[0..2])
  result = prefix4 in 6220..6229 or
           prefix3 in 624..626 or
           prefix4 in 6282..6288