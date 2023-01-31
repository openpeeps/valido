# Valido - A library of string validators and sanitizers
# 
# Originally from Rosetta Code
# https://rosettacode.org/wiki/Luhn_test_of_credit_card_numbers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

proc isCreditCard*(cc: string): bool =
  const m = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]
  var
    t = 0
    odd = true
  for i in countdown(cc.high, 0):
    let digit = ord(cc[i]) - ord('0')
    t += (if odd: digit else: m[digit])
    odd = not odd
  result = t mod 10 == 0