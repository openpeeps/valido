# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

import std/[algorithm, sets, tables, unittest]
import ../src/valido
import ../src/valido/private/country_data

test "extras are enabled for this suite":
  when not defined(validoExtras):
    {.error: "this suite must be compiled with -d:validoExtras".}

test "initExtras is a stable singleton":
  let first = initExtras()
  check first.countries.len > 200
  check first.swiftBanks.len > 100_000
  let second = initExtras()
  check second.countries.len == first.countries.len
  check second.swiftBanks.len == first.swiftBanks.len

test "isCountry":
  check isCountry("US")
  check isCountry("us")
  check isCountry("USA")
  check isCountry("840")
  check isCountry("  US  ")
  check not isCountry("XX")
  check not isCountry("ZZZ")
  check not isCountry("")
  check not isCountry("Atlantis")

test "isCountryName":
  check isCountryName("Canada")
  check isCountryName("canada")
  check isCountryName("United States of America")
  check not isCountryName("Atlantis")
  check not isCountryName("")

test "getCountry":
  let us = getCountry("US")
  check not us.isNil
  check us.info.alpha2 == "US"
  check us.info.alpha3 == "USA"
  check us.info.iso == "840"
  check us.info.capital == "Washington"
  check us.info.tld == "us"
  check us.info.short == "United States"
  check getCountry("usa").info.alpha2 == "US"
  check getCountry("Canada").info.alpha2 == "CA"
  check getCountry("XX").isNil
  check getCountry("").isNil

test "getCountries":
  let all = getCountries()
  check all.len >= 250
  check all.len <= 300
  var codes: seq[string] = @[]
  for country in all:
    codes.add(country.info.alpha2)
  check "US" in codes
  check "CA" in codes
  check "GB" in codes
  check "FR" in codes
  check codes == codes.sorted()

test "isCapital":
  check isCapital("Washington")
  check isCapital("washington")
  check not isCapital("Nowhere City")
  check not isCapital("")

test "isCurrencyCode and getCurrencies":
  check isCurrencyCode("USD")
  check isCurrencyCode("usd")
  check isCurrencyCode("EUR")
  check not isCurrencyCode("XYZ")
  check not isCurrencyCode("")
  let currencies = getCurrencies()
  check "USD" in currencies
  check "EUR" in currencies
  check currencies == currencies.sorted()

test "isLanguageCode and getLanguages":
  check isLanguageCode("eng")
  check isLanguageCode("fra")
  check not isLanguageCode("zzz")
  check not isLanguageCode("")
  let languages = getLanguages()
  check "eng" in languages
  check languages == languages.sorted()

test "isCountryTld":
  check isCountryTld("us")
  check isCountryTld(".us")
  check isCountryTld(".US")
  check isCountryTld("gb")
  check not isCountryTld("zz")
  check not isCountryTld("")
  check not isCountryTld(".")

test "isPhoneCode":
  check isPhoneCode("1")
  check isPhoneCode("44")
  check not isPhoneCode("999")
  check not isPhoneCode("")

test "isState and getStates":
  check isState("NY", "US")
  check isState("ny", "US")
  check not isState("ZZ", "US")
  check not isState("NY", "XX")
  let states = getStates("US")
  check "NY" in states
  check "CA" in states
  check states == states.sorted()
  check getStates("XX").len == 0

test "isPostalCode":
  check isPostalCode("10001", "US")
  check isPostalCode("10001-1234", "US")
  check not isPostalCode("1234", "US")
  check isPostalCode("K1A 0B1", "CA")
  check isPostalCode("K1A0B1", "CA")
  check not isPostalCode("ZZZZZZZ", "CA")
  check not isPostalCode("", "US")
  check not isPostalCode("10001", "XX")

test "isMobile":
  check isMobile("+1 201 555 0123", "US")
  check isMobile("2015550123", "US")
  check not isMobile("+1 000 000 0000", "US")
  check not isMobile("", "US")
  check not isMobile("+1 201 555 0123", "XX")

test "isSwift":
  check isSwift("BOFAUS3N")
  check isSwift("bofa us3n")
  check isSwift("DEUTDEFF")
  check not isSwift("ZZZZZZZZ")
  check not isSwift("BOFAUS3NXXX")
  check not isSwift("")
  check not isSwift("12345678")
  check not isSwift("BOFAUS3")

test "getSwift":
  let bank = getSwift("BOFAUS3N")
  check not bank.isNil
  check bank.name == "BANK OF AMERICA, N.A."
  check bank.city == "NEW YORK,NY"
  check bank.branch == ""
  check bank.code == "BOFAUS3N"
  let branch = getSwift("FTSBUS33SFI")
  check not branch.isNil
  check branch.branch == "SEC FINANCING"
  check getSwift("ZZZZZZZZ").isNil
  check getSwift("").isNil

test "country record exposes the full reference data":
  let us = getCountry("US")
  check "eng" in us.languages
  check "USD" in us.currency.code
  check "United States Dollar" in us.currency.name
  check "1" in us.phone.code
  check 10 in us.phone.length
  check us.postal.regex.len > 0
  check us.postal.regex == "^[0-9]{5}([0-9]{4})?$"
  check "5" in us.postal.length
  check us.states.len > 50
  check us.states["NY"] == "New York"

test "data edge cases":
  # Canada stores its postal regex as a YAML single-quoted scalar so the
  # regex backslashes survive parsing.
  check getCountry("CA").postal.regex ==
    "^[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJ-NPRSTV-Z][\\s\\-]?\\d[ABCEGHJ-NPRSTV-Z]\\d$"
  # Seychelles uses a subdivision code that starts with digits.
  check isState("040s", "SI")
  # United Arab Emirates has bare `name:`/`symbol:` keys, which parse as
  # empty sequences rather than single-element lists.
  let ae = getCountry("AE")
  check not ae.isNil
  check ae.currency.symbol.len == 0
  check ae.currency.name.len == 0
  check "AED" in ae.currency.code
  # An explicit `null` postal regex is an empty string, not the text "null".
  check getCountry("AE").postal.regex == ""
  check getCountry("AE").postal.description == "null"
