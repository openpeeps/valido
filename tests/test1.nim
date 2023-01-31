import std/[unittest, strutils]
import valido
import valido/utils/tlds

test "isEmail (valid)":
  let emails = ["test@example.com", "test.ab@example.com",
                  "123@example.com", "123.123@example.com",
                  "test@example.xyz", "john-john@domain.dev",
                  "hey+2@example.com"]
  for e in emails:
    check isEmail(e) == true

test "isEmail (invalid)":
  let emails = ["", "text.com", "test@example.xyzz", "1.hey@123.cox",
                "^hey@example.com", "hey+@example.com", "x++@foo.co"]
  for e in emails:
    check isEmail(e) == false

test "isDomain (valid)":
  for tld in GetTLDs:
    check isDomain("example." & tld.toLowerAscii) == true

test "isDomain (invalid)":
  check isDomain("sub.example.com") == false

test "isPassword (invalid) `passMinChars` (admin)":
  let output = isPassword("admin")
  check(output.status == false)
  check(output.msg == passMinChars)

test "isPassword (invalid) `passMinUppers` (123admin)":
  let output = isPassword("123admin")
  check(output.status == false)
  check(output.msg == passMinUppers)

test "isPassword (invalid) `passNoSpecials` (123Admin)":
  let output = isPassword("123Admin")
  check(output.status == false)
  check(output.msg == passNoSpecials)

test "isPassword (invalid) `passNoSpecials` (SDK231ksSkall)":
  let output = isPassword("SDK231ksSkall")
  check(output.status == false)
  check(output.msg == passNoSpecials)

test "isPassword (invalid) `passConsecutiveChars` (123Aaadmin)":
  let output = isPassword("123Aaaadmin}")
  check(output.status == false)
  check(output.msg == passConsecutiveChars)

test "isPassword (valid) `passOK` (S<A@#*d)_+las23)":
  let output = isPassword("S<A@#*d)_+las23")
  check(output.status == true)
  check(output.msg == passOK)

test "isCreditCard (valid)":
  check isCreditCard("4101891773067337") == true
  check isCreditCard("4101891773067337") == true

test "isEAN8 (valid)":
  check isEAN8("40123455") == true
  check isEAN8("50123452") == true
  check isEAN8("20166090") == true

test "isEAN8 (invalid)":
  check isEAN8("7654321") == false 

test "isEAN13 (valid)":
  let validEAN13 = [
    "1234567690124",
    "3086126788487",
    "4000000471714",
    "5020650002112",
    "5099750442227",
    "6000931157020",
    "8854740061270",
    "8000000022127",
    "8053469266762",
    "5411786049803",
    "4056489241829",
    "6425262005190",
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

test "isJSON (valid)":
  check isJSON("[true]") == true

test "isJSON (invalid)":
  check isJSON("[true, {}") == false