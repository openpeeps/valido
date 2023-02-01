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

# test "isCC (valid)":
#   check isCC("4101891773067337") == true
#   check isCC("4101891773067337") == true
#   check isCC("3764285348263861") == true

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

test "isBase32 (valid)":
  check isBase32("JBSWY3DPEBLW64TMMQQQ====") == true
  check isBase32("NZUW2IDJOMQGC53FONXW2ZI=") == true
  check isBase32("NB2HI4DTHIXS6Z3JORUHKYROMNXW2L3POBSW44DFMVYA====") == true

test "isBase32 (invalid)":
  check isBase32("MRI=") == false
  check isBase32("2NEpo7TZRRrLZSi2U") == false

test "isBase58 (valid)":
  check isBase58("2NEpo7TZRRrLZSi2U") == true

test "isBase58 (invalid)":
  check isBase58("NZUW2IDJOMQGC53FONXW2ZI=") == false

test "isBase64 (valid)":
  check isBase64("SGVsbG8gV29ybGQhIE5pbSBpcyBBd2Vzb21lIQ==") == true

test "isPort (valid)":
  check isPort(1000) == true
  check isPort("3000") == true
  check isPort(9933, true) == true

test "isPort (invalid)":
  check isPort("244011") == false
  check isPort(1000, true) == false

test "isIP4 (valid)":
  check isIP4("127.0.0.1", allowLoopback = true) == true
  check isIP4("142.251.32.174") == true
  check isIP4("8.8.8.8") == true
  check isIP4("17.253.144.10") == true

test "isIP4 (invalid)":
  check isIP4("2605:2700:0:3::4713:93e3") == false
  check isIP4("127.0.0.1") == false

test "isIP4Reachable (valid)":
  check isIP4Reachable("38.123.217.25") == false

test "isIP6 (valid)":
  check isIP6("2605:2700:0:3::4713:93e3") == true
  check isIP6("2a00:1450:400d:80c::200e") == true

test "isIP6Reachable (invalid)":
  check isIP6Reachable("2605:2700:0:3::4713:93e3") == false