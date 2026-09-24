# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Country reference data and the validators built on top of it.
##
## Everything in this module is only available when compiling with
## `-d:validoExtras`:
##
## ```nim
## nimble c -d:validoExtras
## ```
##
## The reference data is embedded at compile time, so these validators work
## without any files on disk. The first call parses the data and every later
## call reuses it.

when defined(validoExtras):

  import std/[algorithm, sets, strutils, tables]
  import pkg/openparser/regex
  import ./private/country_data

  export country_data.CountryInfo, country_data.CountryCurrency,
    country_data.CountryPhone, country_data.CountryPostal

  type
    Country* = ref object
      ## Full reference data for a single country or territory.
      info*: CountryInfo
      languages*: seq[string]
      currency*: CountryCurrency
      phone*: CountryPhone
      postal*: CountryPostal
      states*: Table[string, string]
        ## Subdivision codes mapped to names, e.g. `NY` to `New York`.

    SwiftBank* = ref object
      ## A single SWIFT/BIC record.
      code*, name*, city*, branch*: string

  var
    countriesByCode = initTable[string, Country]()
    countriesByName = initTable[string, Country]()
    banksByCode = initTable[string, SwiftBank]()
    countriesReady = false

  proc buildCountries() =
    ## Compile the lookup indexes once, from the parsed reference data.
    for _, record in initExtras().countries:
      var country: Country
      new(country)
      country.info = record.info
      country.languages = record.languages
      country.currency = record.currency
      country.phone = record.phone
      country.postal = record.postal
      country.states = record.states
      for key in [record.info.alpha2, record.info.alpha3, record.info.iso,
                  record.info.ioc]:
        if key.len > 0:
          countriesByCode[key.toUpperAscii] = country
      for name in [record.info.short, record.info.long]:
        if name.len > 0:
          countriesByName[name.toLowerAscii] = country

  proc countries(): Table[string, Country] =
    ## Returns the country index, building it on first use.
    if not countriesReady:
      buildCountries()
      countriesReady = true
    result = countriesByCode

  proc banks(): Table[string, SwiftBank] =
    ## Returns the SWIFT index, building it on first use.
    if banksByCode.len == 0:
      for code, record in initExtras().swiftBanks:
        var bank: SwiftBank
        new(bank)
        bank.name = record.name
        bank.city = record.city
        bank.branch = record.branch
        bank.code = code
        banksByCode[code] = bank
    result = banksByCode

  proc getCountry*(code: string): Country =
    ## Looks up a country by alpha-2, alpha-3, ISO numeric or IOC code.
    ## Returns `nil` when the code is unknown.
    let key = code.strip.toUpperAscii
    if key.len == 0: return nil
    result = countries().getOrDefault(key)
    if result.isNil:
      result = countriesByName.getOrDefault(key.toLowerAscii)

  proc getCountries*(): seq[Country] =
    ## Returns every known country and territory, sorted by alpha-2 code.
    discard countries()
    var seen = initHashSet[string]()
    for _, country in countriesByCode:
      let alpha2 = country.info.alpha2
      if alpha2.len == 0 or alpha2 in seen: continue
      seen.incl(alpha2)
      result.add(country)
    result.sort(proc (a, b: Country): int = cmp(a.info.alpha2, b.info.alpha2))

  proc isCountry*(input: string): bool =
    ## Checks if the input is a known country code.
    ##
    ## Accepts an ISO 3166-1 alpha-2 (`US`), alpha-3 (`USA`), numeric
    ## (`840`) or IOC (`USA`) code, case-insensitively.
    let key = input.strip
    if key.len == 0: return false
    result = key.toUpperAscii in countries()

  proc isCountryName*(input: string): bool =
    ## Checks if the input is a known short or long country name,
    ## case-insensitively.
    let key = input.strip.toLowerAscii
    if key.len == 0: return false
    discard countries()
    result = key in countriesByName

  proc isCapital*(input: string): bool =
    ## Checks if the input is a known capital city, case-insensitively.
    let key = input.strip.toLowerAscii
    if key.len == 0: return false
    discard countries()
    for country in countriesByCode.values:
      if country.info.capital.toLowerAscii == key:
        return true

  proc isCurrencyCode*(input: string): bool =
    ## Checks if the input is a currency code used by any known country.
    let key = input.strip.toUpperAscii
    if key.len == 0: return false
    discard countries()
    for country in countriesByCode.values:
      if key in country.currency.code:
        return true

  proc getCurrencies*(): seq[string] =
    ## Returns every known currency code, sorted and deduplicated.
    var seen = initHashSet[string]()
    discard countries()
    for country in countriesByCode.values:
      for code in country.currency.code:
        if code in seen: continue
        seen.incl(code)
        result.add(code)
    result.sort()

  proc isLanguageCode*(input: string): bool =
    ## Checks if the input is a language code used by any known country.
    let key = input.strip.toLowerAscii
    if key.len == 0: return false
    discard countries()
    for country in countriesByCode.values:
      if key in country.languages:
        return true

  proc getLanguages*(): seq[string] =
    ## Returns every known language code, sorted and deduplicated.
    var seen = initHashSet[string]()
    discard countries()
    for country in countriesByCode.values:
      for code in country.languages:
        if code in seen: continue
        seen.incl(code)
        result.add(code)
    result.sort()

  proc isCountryTld*(input: string): bool =
    ## Checks if the input is a country-code top-level domain, with or
    ## without a leading dot (e.g. `us` or `.us`).
    var key = input.strip.toLowerAscii
    if key.startsWith("."): key = key[1 .. ^1]
    if key.len == 0: return false
    discard countries()
    for country in countriesByCode.values:
      if country.info.tld.toLowerAscii == key:
        return true

  proc isPhoneCode*(input: string): bool =
    ## Checks if the input is a known international dialling code.
    let key = input.strip
    if key.len == 0: return false
    discard countries()
    for country in countriesByCode.values:
      if key in country.phone.code:
        return true

  proc isState*(stateCode: string, alpha2: string): bool =
    ## Checks if `stateCode` is a subdivision of the given alpha-2 country.
    ##
    ## Subdivision codes are matched case-insensitively; a few territories
    ## store them in lower case (for example `040s` in Slovenia).
    let country = getCountry(alpha2)
    if country.isNil: return false
    let code = stateCode.strip
    if code.len == 0: return false
    result = country.states.hasKey(code) or
             country.states.hasKey(code.toUpperAscii)

  proc getStates*(alpha2: string): seq[string] =
    ## Returns the subdivision codes of a country, sorted.
    let country = getCountry(alpha2)
    if country.isNil: return
    for code in country.states.keys:
      result.add(code)
    result.sort()

  proc isPostalCode*(input: string, alpha2: string): bool =
    ## Checks if the input is a valid postal code for the given country.
    ##
    ## Redundant characters listed by the country (spaces and dashes) are
    ## ignored. When the country publishes a postal regex that regex decides
    ## the result; otherwise the declared lengths and character set are used.
    let country = getCountry(alpha2)
    if country.isNil: return false

    var candidate = input.strip.toUpperAscii
    if candidate.len == 0: return false

    for ch in country.postal.redenundant_chars:
      candidate = candidate.replace($ch, "")
    if candidate.len == 0: return false

    if country.postal.regex.len > 0:
      var vm = initRegexVM(compile(country.postal.regex))
      return vm.match(candidate).matched

    if country.postal.length.len == 0: return false
    if $candidate.len notin country.postal.length: return false
    if country.postal.charset.toLowerAscii == "number":
      for ch in candidate:
        if ch notin {'0' .. '9', ' '}: return false
    result = true

  proc isMobile*(input: string, alpha2: string): bool =
    ## Checks if the input is a valid mobile number for the given country.
    ##
    ## Accepts the number with or without its international prefix. When the
    ## country lists mobile prefixes, the national number must start with
    ## one of them; otherwise only the length is checked.
    let country = getCountry(alpha2)
    if country.isNil: return false

    var digits = ""
    for ch in input.strip:
      if ch in {'0' .. '9'}:
        digits.add(ch)

    var national = digits
    for code in country.phone.code:
      if national.len > code.len and national.startsWith(code):
        let rest = national[code.len .. ^1]
        if country.phone.length.len == 0 or $rest.len in $country.phone.length:
          national = rest
          break

    if country.phone.length.len > 0 and national.len notin country.phone.length:
      return false
    if country.phone.mobile_prefix.len == 0: return true
    for prefix in country.phone.mobile_prefix:
      if $prefix in national:
        return true

  proc isSwift*(input: string): bool =
    ## Checks if the input is a known SWIFT/BIC code.
    ##
    ## A BIC is four letters for the bank, two for the country, two
    ## alphanumeric for the location and an optional three character branch.
    ## Spacing and dashes are ignored.
    var code = ""
    for ch in input.strip:
      if ch.isAlphaNumeric:
        code.add(ch.toUpperAscii)
    if code.len != 8 and code.len != 11: return false
    for i in 0 ..< 8:
      if i < 6 and code[i] notin {'A' .. 'Z'}: return false
      if not code[i].isAlphaNumeric: return false
    discard banks()
    result = code in banksByCode

  proc getSwift*(input: string): SwiftBank =
    ## Looks up a SWIFT/BIC code and returns the bank record.
    ## Returns `nil` when the code is unknown.
    var code = ""
    for ch in input.strip:
      if ch.isAlphaNumeric:
        code.add(ch.toUpperAscii)
    if code.len != 8 and code.len != 11: return nil
    result = banks().getOrDefault(code)
