<p align="center">
  <img src="https://github.com/openpeep/valido/blob/main/.github/logo.png" width="64px"><br>
  A library of string validators and sanitizers.<br>👑 Written in Nim language
</p>

<p align="center">
  <code>nimble install valido</code> *(not published, yet)
</p>

<p align="center">
  <a href="https://openpeep.github.io/valido/">API reference</a><br>
  <img src="https://github.com/openpeep/valido/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeep/valido/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- [x] Framework agnostic
- [ ] Zero RegExp
- [x] is `Base32`, `Base58`, `Base64`
- [x] is `Email`
- [x] is `IP4`, `IP6`
- [x] is `IBAN`
- [x] is Strong `Password`
- [x] is `Port`
- [x] is `URI`
- [x] is `UUID`
- [x] is `JSON`
- [x] is `Lowercase`, `Uppercase`, `Alpha`, `Alphanumerical`, `Digits`
- [x] is `Boolean`, `Int`, `Float`, `Hex`, `Regex`
- [x] Open Source | `MIT` License
- [x] Written in Nim language

## Examples
```nim
import valido/[email, ip]

assert isEmail("office@example.com") == true
assert isIP4("127.0.0.1", allowLoopback = false) == false

assert isStrongPassword("123adminAdmin") == false

```

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeep/valido/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeep/valido/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)
- 🥰 [Donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
Valido | MIT license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2023 OpenPeep & Contributors &mdash; All rights reserved.
