import std/[unittest, strutils]
import valido
import valido/utils/tlds

test "Valid isEmail":
  let emails = ["test@example.com", "test.ab@example.com",
                  "123@example.com", "123.123@example.com",
                  "test@example.xyz", "john-john@domain.dev",
                  "hey+2@example.com"]
  for e in emails:
    check isEmail(e) == true

test "Invalid isEmail":
  let emails = ["", "text.com", "test@example.xyzz", "1.hey@123.cox",
                "^hey@example.com", "hey+@example.com", "x++@foo.co"]
  for e in emails:
    check isEmail(e) == false

test "Valid TLD":
  for tld in GetTLDs:
    check isDomain("example." & tld.toLowerAscii) == true

test "Invalid TLD":
  check isDomain("sub.example.com") == false

test "Check password strength | `passMinChars` (admin)":
  let output = isPassword("admin")
  check(output.status == false)
  check(output.msg == passMinChars)

test "Check password strength | `passMinUppers` (123admin)":
  let output = isPassword("123admin")
  check(output.status == false)
  check(output.msg == passMinUppers)

test "Check password strength | `passNoSpecials` (123Admin)":
  let output = isPassword("123Admin")
  check(output.status == false)
  check(output.msg == passNoSpecials)

test "Check password strength | `passNoSpecials` (SDK231ksSkall)":
  let output = isPassword("SDK231ksSkall")
  check(output.status == false)
  check(output.msg == passNoSpecials)

test "Check password strength | `passConsecutiveChars` (123Aaadmin)":
  let output = isPassword("123Aaaadmin}")
  check(output.status == false)
  check(output.msg == passConsecutiveChars)

test "Check password strength | `passOK` (S<A@#*d)_+las23)":
  let output = isPassword("S<A@#*d)_+las23")
  check(output.status == true)
  check(output.msg == passOK)