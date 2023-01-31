import unittest
import valido

test "isEAN8 (valid)":
  check isEAN8("40123455") == true
  check isEAN8("50123452") == true

test "isEAN8 (invalid)":
  check isEAN8("7654321") == false 

test "isEAN13 (valid)":
  let validEAN13 = [
    "1234567690124", 
    "4000000471714",
    "5020650002112",
    "5099750442227",
    "6000931157020",
    "8854740061270",
    "8000000022127",
    "8053469266762",
  ]
  for ea in validEAN13:
    check isEAN(ea) == (true, EAN13)

test "isEAN13 (invalid)":
  let invalidEAN13 = [
    "8053469266761",
    "aa53469266761",
  ]
  for ea in invalidEAN13:
    check isEAN(ea) == (false, InvalidEAN)