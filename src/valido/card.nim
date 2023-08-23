# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

from std/strutils import parseInt, multiReplace

proc checkLuhn(cc: string): bool =
  # Luhn's algorithm. Originally from Rosetta Code
  # https://rosettacode.org/wiki/Luhn_test_of_credit_card_numbers
  const m = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]
  var
    t = 0
    odd = true
  for i in countdown(cc.high, 0):
    let digit = ord(cc[i]) - ord('0')
    t += (if odd: digit else: m[digit])
    odd = not odd
  result = t mod 10 == 0

proc isCard*(input: string): bool = checkLuhn(input)

proc isVisa*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin [16, 19]: return
  if isCard(cc):
    result = cc[0] == '4'

proc isMasterCard*(input: string): bool =
  # https://www.mastercard.us/en-us/business/issuers/get-support/simplified-bin-account-range-table.html
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len != 16: return
  if isCard(cc):
    if parseInt(cc[0..1]) in {23..26, 51..55}:
      result = true
    elif parseInt(cc[0..3]) in 2221..2229:
      result = true
    elif parseInt(cc[0..2]) in 270..271:
      result = true

proc isMaestro*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin 12..19: return
  if isCard(cc):
    let i = parseInt(cc[0..2])
    return i in 500..509 or i in 560..589 or i in 600..699 # seems like {500..509, 560..589, ...} does not work with nim 2.0

proc isAmericanExpress*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len != 15: return
  if isCard(cc):
    result = cc[0..1] in ["34", "37"]

proc isAMEX*(input: string): bool =
  ## An alias of `isAmericanExpress`
  result = isAmericanExpress(input)

proc isDiscover*(input: string): bool =
  # https://www.discoverglobalnetwork.com/resources/payments-providers/bin-ranges/
  # https://www.discoverglobalnetwork.com/content/dam/discover/en_us/dgn/docs/IPP-VAR-Enabler-Compliance.pdf
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin [16, 19]: return
  if isCard(cc):
    if parseInt(cc[0..1]) == 65:
      result = true
    elif parseInt(cc[0..3]) == 6011:
      result = true
    elif parseInt(cc[0..3]) in 644..649:
      result = true
    elif parseInt(cc[0..5]) in 622126 .. 622925:
      result = true

proc isChinaUnionPay*(input: string): bool =
  var cc = input.multiReplace((" ", ""), ("-", ""))
  if cc.len notin {16..19}: return
  # TODO