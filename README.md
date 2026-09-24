<p align="center">
  <img src="https://github.com/openpeeps/valido/blob/main/.github/logo.png" width="64px"><br>
  A library of string validators and sanitizers.<br>👑 Written in Nim language
</p>

<p align="center">
  <code>nimble install valido</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/valido/">API reference</a><br>
  <img src="https://github.com/openpeeps/valido/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeeps/valido/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- [x] Framework agnostic
- [x] Mostly zero RegExp (format validators delegate to [openparser](https://github.com/openpeeps/openparser))
- [x] is `Base32`, `Base58`, `Base64` (standard and URL-safe)
- [x] is `MD5`
- [x] is `Email`
- [x] is `Domain`
- [x] is `IP4`, `IP6` (plus reachability checks)
- [x] is `IBAN`
- [x] is `EAN8`, `EAN13` (with type detection via `isEAN`)
- [x] is `CARD` (BIN/IIN support for `Visa`, `MasterCard`, `Maestro`, `Discovery`, `JCB`, `DinersClub`, `Mir`, `ChinaUnionPay`, `AmericanExpress`)
- [x] is Strong `Password`
- [x] is `Port`
- [x] is `URI`, `URL` with 23+ per-scheme format validators
- [x] is `UUID` (versions 1 through 8, dashed or dashless, nil UUID)
- [x] is `JSON`, `YAML`, `TOML`
- [x] is `Regex` pattern and match
- [x] is `Date`, `PastDate`, `FutureDate`, `Today` with custom formats
- [x] is `Lowercase`, `Uppercase`, `Alpha`, `Alphanumerical`, `Digits`, `Boolean`, `Int`, `Float`, `HexStr`
- [x] is `Length`: `isEmpty`, `isNotEmpty`, `isMin`, `isMax`, `isBetween`
- [x] is `Color`: `Hex`, `Rgb`, `Rgba`, `Hsl`, `Hsla`, `Hsv`, `Hwb`, `Cmyk`, `Lab`, `Lch`, `Oklab`, `Oklch`, `NamedColor`, `Transparent` (CSS Color 4)
- [ ] is Country (countries, currency, languages, phone, postal data)
- [x] Open Source | `MIT` License
- [x] Written in Nim language

## Examples

### Quick start
```nim
import valido

assert isEmail("office@example.com")
assert not isIP4("127.0.0.1")          # loopback is opt-in
assert isIP4("127.0.0.1", allowLoopback = true)
assert not isStrongPassword("123adminAdmin")
```

Most validators return a plain `bool`. `isUUID` additionally accepts a version
selector, `isUri` accepts a scheme selector, and `isEAN` returns a
`(status, type)` tuple.

### Text and strings
```nim
import valido

assert isLowercase("lorem")
assert isLowercase("lorem ipsum", withWhitespaces = true)
assert isLowercase("lorem ipsum 2023", true, true)
assert isUppercase("LOREM IPSUM", withWhitespaces = true)

assert isAlpha("abcdefgh")
assert isAlpha("no more lorem", withWhitespaces = true)
assert isAlphaNumeric("mystuff2")
assert isAlphaNumeric("one 2 3", withWhitespaces = true)

assert isDigits("1234554321")
assert isDigits("1234-554-321", '-')    # allow a separator

assert isBoolean("true")
assert isFloat("20.99")
assert isInt("42")
assert isHexStr("48656c6c6f20576f726c64")

assert isEmpty("")
assert isNotEmpty("x")
assert isMin("hello", 3)
assert isMax("hello", 10)
assert isBetween("hello", (2, 8))
```

### Encodings
```nim
import valido

assert isBase32("JBSWY3DPEBLW64TMMQQQ====")
assert isBase58("2NEpo7TZRRrLZSi2U")
assert isBase64("SGVsbG8gV29ybGQhIE5pbSBpcyBBd2Vzb21lIQ==")
assert isBase64("a-b_c", urlSafe = true)
assert isMD5("900150983cd24fb0d6963f7d28e17f72")
```

### Network, email and hosts
```nim
import valido

assert isEmail("john-john@domain.dev")
assert isEmail("hey+2@example.com")
assert isEmail("x!y@example.com", allowSpecialChars = true)
assert isDomain("example.com")

assert isIP4("8.8.8.8")
assert isIP6("2a00:1450:400d:80c::200e")
assert not isIP4Reachable("0.0.0.0", timeout = 1000)  # performs a socket connect

assert isPort(8080)
assert isPort("3000")
assert isPort(80, strict = false)      # 0..65535
assert isPort(8443, strict = true)     # 1024..65535
```

### URIs and URLs
`isUri` and `isUrl` dispatch to a per-scheme validator that checks the full
string format, not just the scheme name.

```nim
import valido

assert isUri("https://example.com/path?q=1#frag")
assert isUri("bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", SchemeURI.Bitcoin)
assert isUri("ftp://user@example.com/file.txt", SchemeURI.Ftp)

assert isWebUrl("https://user:pass@example.com:8080/path")
assert isUrl("http://example.com")            # alias of isWebUrl
assert getScheme("https://example.com") == SchemeURI.Https

assert isFtpUri("ftp://user:pass@example.com:21/files")
assert isSftpUri("sftp://deploy@example.com/var/www/index.html")
assert isSshUri("ssh://deploy@192.168.1.1:22/var/www")
assert isGitUri("git://github.com/user/repo.git")
assert isGitUri("https://github.com/user/repo.git")
assert isMailto("mailto:hello@example.com")
assert isFileUri("file:///home/user/docs/file.txt")

assert isAndroidUri("android://com.example.app")
assert isBitcoinUri("bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.1&label=test")
assert isBitcoinCashUri("bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a")
assert isChromeUri("chrome://browser/content/browser.xul")
assert isChromeExtensionUri("chrome-extension://abcdefghijklmnopqrstuvwxyzabcdef/index.html")
assert isFaceTimeUri("facetime://+19995551234")
assert isFeedUri("feed://example.com/feed.xml")
assert isIrcUri("irc://irc.example.com:6697/#channel")
assert isIrc6Uri("irc6://irc.example.com/#channel")
assert isIrcsUri("ircs://irc.example.com/#channel")
assert isLdapsUri("ldaps://ldap.example.com:636/dc=example,dc=com")
assert isMongoDbUri("mongodb://user:pass@host1:27017,host2:27017/mydb?replicaSet=rs0")
assert isMarketUri("market://details?id=com.example.app")
assert isMessageUri("message:<1234@example.com>")
```

### Data formats
```nim
import valido

assert isJSON("""{"name":"Albush","age":40}""")
assert isYaml("host: localhost\nport: 8080")
assert isYaml("- a\n- b\n- c")
assert isYamlStream("a: 1\n---\nb: 2")
assert isToml("[server]\nhost = \"localhost\"\nport = 8080")
```

`isYaml` and `isToml` delegate to openparser, so strictness follows those
parsers. A YAML plain scalar such as `"hello"` is valid YAML.

### Regular expressions
```nim
import valido

assert isRegex("""(\w+)=(\w+)""")
assert not isRegex("*")
assert isRegexMatch("""(\w+)=(\w+)""", "foo=bar")   # full input match
assert not isRegexMatch("""(\w+)=(\w+)""", "hello world")
```

### UUIDs
```nim
import valido

assert isUUID("550e8400-e29b-41d4-a716-446655440000")
assert isUUID("550e8400-e29b-41d4-a716-446655440000", V4)
assert isUUID("550e8400e29b41d4a716446655440000")            # dashless
assert not isUUID("550e8400e29b41d4a716446655440000", strictDashes = true)
assert isNilUUID("00000000-0000-0000-0000-000000000000")
```

### Colors
CSS Color 4 is supported through openparser. `isColor` accepts any supported
notation, while the granular helpers only accept their own syntax.

```nim
import valido

assert isColor("red")
assert isColor("rebeccapurple")
assert isColor("#ff0000")
assert isColor("rgb(255 0 0 / 0.5)")
assert isColor("hsl(0 100% 50%)")
assert isColor("oklch(0.7 0.15 180)")
assert isColor("transparent")

assert isHex("#ff0000")
assert isHex("f00")            # 3, 4, 6 or 8 digits, `#` optional
assert isHexColor("#ff000080")

assert isRgb("rgb(255, 0, 0)")
assert isRgba("rgba(255, 0, 0, 0.5)")
assert isRgba("rgb(255 0 0 / 0.5)")
assert isHsl("hsl(0, 100%, 50%)")
assert isHsla("hsla(0, 100%, 50%, 0.5)")
assert isHsv("hsv(120, 100%, 100%)")
assert isHwb("hwb(120 20% 20%)")
assert isCmyk("cmyk(0%, 100%, 100%, 0%)")
assert isLab("lab(53.2 80.1 67.2)")
assert isLch("lch(54.3 106.8 40.9)")
assert isOklab("oklab(0.628 0.225 0.126)")
assert isOklch("oklch(0.7 0.15 180)")
assert isNamedColor("RebeccaPurple")   # case-insensitive
assert isTransparent("transparent")
```

### Dates
```nim
import valido

assert isDate("2023-01-05")
assert isDate("2023-01-05 2:30pm", "yyyy-MM-dd h:mtt")
assert isPastDate("2022-01-03")
assert isFutureDate("2030-03-03")
assert isToday("2026-09-24")
```

### Finance and commerce
```nim
import valido

assert isIBAN("BE71096123456769")

assert isEAN8("40123455")
assert isEAN13("1234567690124")
assert isEAN("1234567690124") == (true, EAN13)   # returns status and type

assert isCard("4111111111111111")   # Luhn check
assert isVisa("4111111111111111")
assert isMasterCard("2222400050000009")
assert isMaestro("6759649826438453")
assert isAmericanExpress("371449635398431")
assert isAMEX("340000000000009")
assert isDiscover("6011111111111117")
assert isJCB("3530111333300000")
assert isDinersClub("30569309025904")
assert isMir("2200000000000004")
assert isChinaUnionPay("6221260000000000")
```

### Security
```nim
import valido

assert isStrongPassword("x6y2C8D@#$(t5Lgg")
assert not isStrongPassword("123adminAdmin")
assert isStrongPassword("correct-horse-Battery-9!", defaultEntropy = 4.0)
```

## Extra features
`todo` Enable extra features by passing `-d:validoCountries`. This includes information
about all `countries`, `currency`, `languages`, `phone` codes/prefixes/length, `postal` information and `states`.

## IBAN with SWIFT information
`todo` Enable IBAN validation by passing `-d:validoSwiftCodes`

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/valido/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/valido/fork)

### 🎩 License
Valido | MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; OpenPeeps & Contributors &mdash; All rights reserved.
