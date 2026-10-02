import std/[strutils, unicode, unittest]
import ../src/valido
import ../src/valido/utils/suffixes
import ../src/valido/utils/tlds

suite "IDNA":

  test "toNfc":
    check toNfc("") == ""
    check toNfc("example") == "example"
    check toNfc("a\u0308") == "\u00E4"
    check toNfc("\u00E4") == "\u00E4"
    check toNfc("A\u030A") == "\u00C5"
    check toNfc("a\u0300\u0301") == "\u00E0\u0301"
    check toNfc("\u1100\u1161") == "\uAC00"          # Hangul is composed
    check toNfc("\u212B") == "\u00C5"               # Angstrom sign
    check toNfc("\u0344") == "\u0308\u0301"         # composition exclusion
    check isNfc("\u00E4")
    check not isNfc("a\u0308")

  test "Punycode":
    check punycodeEncode("m\u00FCnchen") == "xn--mnchen-3ya"
    check punycodeDecode("xn--mnchen-3ya") == "m\u00FCnchen"
    # A U-label is not Punycode, so there is nothing to decode
    check punycodeDecode("m\u00FCnchen") == ""
    check punycodeEncode("example") == ""
    check punycodeDecode("xn--not-punycode-at-all!!") == ""
    check punycodeDecode("xn--") == ""
    check isAce("xn--mnchen-3ya")
    check isAce("XN--MNCHEN-3YA")
    check not isAce("example")
    check not isAce("xn--")

  test "toAscii (nontransitional)":
    check toAscii("example.com") == "example.com"
    check toAscii("EXAMPLE.COM") == "example.com"
    check toAscii("m\u00FCnchen.de") == "xn--mnchen-3ya.de"
    check toAscii("xn--mnchen-3ya.de") == "xn--mnchen-3ya.de"
    check toAscii("\u65E5\u672C\u8A9E.jp") == "xn--wgv71a119e.jp"
    check toAscii("\uFF45\uFF58\uFF41\uFF4D\uFF50\uFF4C\uFF45.com") == "example.com"
    check toAscii("\u30C6\u30B9\u30C8.\u30C6\u30B9\u30C8") ==
          "xn--zckzah.xn--zckzah"
    check toAscii("fa\u00DF.de") == "xn--fa-hia.de"
    check toAscii("\u00E5\u00E5\u00E5.no") == "xn--5caaa.no"
    # A ZWNJ only survives inside a joining sequence or after a virama
    check toAscii("\u0646\u0627\u0645\u0647\u200C\u0627\u06CC.com") ==
          "xn--mgba3gch31f060k.com"
    check toAscii("a\u200Cb") == ""
    check toAscii("a\u200Db") == ""

  test "toAscii (transitional)":
    check toAscii("fa\u00DF.de", transitional = true) == "fass.de"
    check toAscii("\u03C2.com", transitional = true) == "xn--4xa.com"
    check toAscii("a\u200Cb", transitional = true) == "ab"
    # Punycode is never remapped, so an explicit deviation character survives.
    check toAscii("xn--fa-hia.de", transitional = true) == "xn--fa-hia.de"

  test "toAscii (invalid)":
    check toAscii("") == ""
    check toAscii("exam ple.com") == ""
    check toAscii("example..com") == ""
    check toAscii("-example.com") == ""
    check toAscii("example.com-") == ""
    check toAscii("ex--ample.com") == ""          # hyphens in 3rd and 4th
    check toAscii("\u0020\u0301.com") == ""       # leading combining mark
    check toAscii("\u00E0\u05D0") == ""           # bidi rules
    check toAscii("xn--mnchen-3ya\u00DF.de") == "" # non ASCII in an ACE label
    check toAscii("xn--a.com-") == ""
    check toAscii("0\u00E0.\u05D0") == ""         # European number first
    check toAscii("$") == ""                      # STD3 ASCII rules
    check toAscii("xn--.com") == ""               # no punycode payload
    check toAscii("xn--a.com-") == ""             # hyphen at the end
    check toAscii("xn--a-.com") == ""

  test "toUnicode":
    check toUnicode("example.com") == "example.com"
    check toUnicode("xn--mnchen-3ya.de") == "m\u00FCnchen.de"
    check toUnicode("xn--fa-hia.de") == "fa\u00DF.de"
    check toUnicode("a\u0300b.com") == "\u00E0b.com"
    check toUnicode("XN--MNCHEN-3YA.DE") == "m\u00FCnchen.de"
    check toUnicode("exam ple.com") == ""
    check toUnicode("") == ""

  test "tryToAscii / tryToUnicode":
    let (ascii, asciiOk) = tryToAscii("m\u00FCnchen.de")
    check asciiOk
    check ascii == "xn--mnchen-3ya.de"
    check tryToAscii("exam ple.de")[1] == false
    let (unicode, unicodeOk) = tryToUnicode("xn--mnchen-3ya.de")
    check unicodeOk
    check unicode == "m\u00FCnchen.de"
    check tryToUnicode("exam ple.de")[1] == false

  test "isIdn":
    check isIdn("example.com")
    check isIdn("m\u00FCnchen.de")
    check isIdn("xn--mnchen-3ya.de")
    check not isIdn("exam ple.de")
    check not isIdn("sub_domain.example.com")

  test "idnaStatus":
    check idnaStatus(Rune(0x0061'u32)) == idnaValid
    check idnaStatus(Rune(0x0041'u32)) == idnaMapped
    check idnaStatus(Rune(0x00DF'u32)) == idnaDeviation
    check idnaStatus(Rune(0x00AD'u32)) == idnaIgnored
    check idnaStatus(Rune(0xFFFD'u32)) == idnaDisallowed  # replacement char
    check idnaMapping(Rune(0x0041'u32)) == "a"
    check idnaMapping(Rune(0x00DF'u32)) == "ss"
    check idnaMapping(Rune(0x0061'u32)) == ""
    check isExcludedByIdna2008(Rune(0x1F4A9'u32))       # emoji
    check not isExcludedByIdna2008(Rune(0x00FC'u32))    # u with diaeresis

suite "Domains":

  test "isDomain (valid)":
    for tld in GetTLDs:
      check isDomain("example." & tld.toLowerAscii) == true

  test "isDomain (internationalized)":
    check isDomain("m\u00FCnchen.de")
    check isDomain("M\u00DCNCHEN.DE")
    check isDomain("xn--mnchen-3ya.de")
    check isDomain("XN--MNCHEN-3YA.DE")
    check isDomain("fa\u00DF.de")
    check isDomain("xn--fa-hia.de")
    check isDomain("\u65E5\u672C\u8A9E.jp")
    check isDomain("\uD55C\uAD6D\uC5B4.com")
    check isDomain("\u0646\u0627\u0645\u0647\u200C\u0627\u06CC.com")
    check isDomain("\uFF45\uFF58\uFF41\uFF4D\uFF50\uFF4C\uFF45.com")

  test "isDomain (invalid)":
    check isDomain("sub.example.com") == false     # see isSubDomain
    check isDomain("") == false
    check isDomain("localhost") == false
    check isDomain("exam ple.com") == false
    check isDomain("example.invalid") == false
    check isDomain("-example.com") == false
    check isDomain("example-.com") == false
    check isDomain("example..com") == false
    check isDomain("192.168.0.1") == false
    check isDomain("example.com.") == false
    check isDomain("example.com/path") == false
    check isDomain("example.com:80") == false
    check isDomain("\u0020example.com") == false
    # A soft hyphen is an ignored code point, UTS #46 drops it
    check isDomain("exam\u00ADple.com")

  test "isDomain (flags)":
    check isDomain("example.invalid", checkTld = false)
    check isDomain("example.com.", allowTrailingDot = true)
    check not isDomain("example.com.")
    check isDomain("*.example.com", allowWildcard = true)
    check not isDomain("*.example.com")
    check isSubDomain("_dmarc.example.com", allowUnderscore = true)
    check not isDomain("_dmarc.example.com", allowUnderscore = true)
    # UTS #46 allows what IDNA2008 excludes, strict turns that away.
    check not isDomain("\u{1F4A9}.com")
    check not isDomain("xn--ls8h.com")
    check isDomain("xn--ls8h.com", strict = false)
    check isDomain("\u{1F4A9}.com", strict = false)
    # A deviation character maps to "ss" only with transitional processing.
    check isDomain("fa\u00DF.de")
    check toAscii("fa\u00DF.de", transitional = true) == "fass.de"

  test "isSubDomain (valid)":
    check isSubDomain("sub.example.com")
    check isSubDomain("a.b.example.com")
    check isSubDomain("www.m\u00FCnchen.de")
    check isSubDomain("xn--mnchen-3ya.sub.example.com")
    check isSubDomain("_dmarc.example.com", allowUnderscore = true)
    check isSubDomain("*.sub.example.com", allowWildcard = true)
    check isSubDomain("mail.example.com.", allowTrailingDot = true)
    check not isSubDomain("mail.example.com.")
    check not isSubDomain("example.com")

  test "isSubDomain (country code suffixes)":
    check isSubDomain("example.co.uk")
    check isSubDomain("www.example.co.uk")
    check isSubDomain("example.com.au")
    check not isSubDomain("example.co.zz")
    check not isSubDomain("co.uk")
    check "co.uk" in GetPublicSuffixes
    check "XN--P1AI" in GetTLDs

  test "isSubDomain (invalid)":
    check isSubDomain("sub..example.com") == false
    check isSubDomain("sub.example.invalid") == false
    check isSubDomain("sub exam.example.com") == false
    check isSubDomain("sub\u00AD.example.com")
    check isSubDomain("") == false

  test "the domain lists stay sorted":
    # `isDomain` and `isSubDomain` binary search these lists
    var last = ""
    for entry in GetTLDs:
      check entry > last
      last = entry
    last = ""
    for entry in GetPublicSuffixes:
      check entry > last
      last = entry
    # every entry has to be findable, which is what the search depends on
    for entry in GetPublicSuffixes:
      check isSubDomain("sub.example." & entry)
    for entry in ["co.uk", "com.au", "org.jp", "co.za"]:
      check isSubDomain("sub.example." & entry)

  test "label and length limits":
    let
      long63 = "a".repeat(63)
      long64 = "a".repeat(64)
      longName = "a".repeat(63) & "." & "b".repeat(63) & "." & "c".repeat(63) &
                 ".d" & "d".repeat(61) & ".com"
    check isDomain(long63 & ".com")
    check not isDomain(long64 & ".com")
    check not isSubDomain(longName)
    check not isSubDomain("a".repeat(250) & ".com")

suite "Email domains":

  test "isEmail with IDN domains":
    check isEmail("test@xn--mnchen-3ya.de")
    check isEmail("test@m\u00FCnchen.de", allowIdn = true)
    check not isEmail("test@m\u00FCnchen.de")
    check not isEmail("test@example.invalid")
    check not isEmail("test@exam ple.com")

suite "URI hosts":

  test "internationalized hosts":
    check isWebUrl("https://m\u00FCnchen.de/path")
    check isWebUrl("https://xn--mnchen-3ya.de/path")
    check isWebUrl("https://sub.example.com/path")
    check not isWebUrl("https://exam ple.de/path")
    check isWebUrl("https://localhost:8080/path")