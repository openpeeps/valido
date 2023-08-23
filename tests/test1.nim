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

test "isStrongPassword (valid)":
  check isStrongPassword("x6y2C8Dt5Lgg") == true

test "isStrongPassword (invalid)":
  check isStrongPassword("123admin@Admin321") == false

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
  check isIP4Reachable("38.242.217.25", timeout = 10000) == true

test "isIP6 (valid)":
  check isIP6("2605:2700:0:3::4713:93e3") == true
  check isIP6("2a00:1450:400d:80c::200e") == true

test "isIP6Reachable (invalid)":
  check isIP6Reachable("2605:2700:0:3::4713:93e3") == false

test "isLowercase / isUppercase (valid)":
  check isLowercase("lorem", true) == true
  check isLowercase("lorem ipsum dolor sit amet", true) == true
  check isLowercase("lorem ipsum dolor sit amet 2023", true, true) == true
  
  check isUppercase("LOREM IPSUM DOLOR SIT AMET", true) == true
  check isUppercase("LOREM IPSUM DOLOR SIT AMET 2023", true, true) == true

test "isLowercase / isUppercase (invalid)":
  check isLowercase("lo rem") == false
  check isLowercase("lorem123") == false
  check isLowercase("lorem IPSUM DOLOR SIT AMET", true) == false
  check isUppercase("LOREM ipsum dolor sit amet", true) == false
  check isUppercase("LO REM") == false
  check isLowercase("bro stop with latin") == false

test "isDigits (valid)":
  check isDigits("1234554321") == true
  check isDigits("1234-554-321", '-') == true

test "isDigits (invalid)":
  check isDigits("12345 54321") == false
  check isDigits("1234-554-321") == false
  check isDigits("1234_554", '-') == false

test "isAlpha / isAlphaNumeric (valid)":
  check isAlpha("abcdefgh") == true
  check isAlpha("no more lorem ipsum", true) == true
  check isAlphaNumeric("mystuff2") == true
  check isAlphaNumeric("one 2 3", true) == true

test "isAlpha / isAlphaNumeric (invalid)":
  check isAlpha("123") == false
  check isAlpha("no more spaces") == false
  check isAlphaNumeric("mystuff@example", true) == false
  check isAlphaNumeric("one 2 3") == false

test "isDigits / isFloat / isBoolean / isRegex (valid)":
  check isBoolean("true") == true
  check isFloat("20.99") == true
  check isHexStr("48656c6c6f20576f726c64") == true
  check isRegex("(\\w+)=(\\w+)") == true

test "isDigits / isFloat / isBoolean / isRegex (invalid)":
  check isBoolean("yeah") == false
  check isFloat("20,99") == false
  check isHexStr("48656c6c6 f20576f726c64") == false
  check isRegex("*") == false

#test "isIBAN":
  # check isIBAN("BE71096123456769")

test "isMD5":
  check isMD5("900150983cd24fb0d6963f7d28e17f72") == true
  check isMD5("900150983cd24fb0d6963f7d28x07f72") == false

test "isPastDate / isDate / isToday / isFutureDate (valid)":
  check isPastDate("2022-01-03") == true
  check isDate("2023-01-05") == true
  check isFutureDate("2030-03-03") == true

  check isPastDate("2022-01-03 14:00", "yyyy-MM-dd hh:mm") == true
  check isDate("2023-01-05 2:30pm", "yyyy-MM-dd h:mtt") == true
  check isFutureDate("2030-03-03 17:00", "yyyy-MM-dd hh:mm") == true

test "isCard (valid)":
  check isCard("4101891773067337") == true
  check isCard("4101891773067337") == true
  check isCard("3764285348263861") == true

test "isMasterCard (valid)":
  check isMasterCard("2222 4000 7000 0005") == true
  check isMasterCard("5577 0000 5577 0004") == true
  check isMasterCard("2222400050000009") == true

test "isMaestro (valid)":
  check isMaestro("6759649826438453") == true
  check isMaestro("6799990100000000019") == true
  check isMaestro("6771 7980 2100 0008") == true
  check isMaestro("6331101999990073") == true
  check isMaestro("6304939304310009610") == true

test "isDiscover (valid)":
  check isDiscover("6011111111111117") == true
  check isDiscover("6011000990139424") == true