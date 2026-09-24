# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Compile-time embedded country and SWIFT/BIC reference data.
##
## Every YAML file under `private/data/countries` is embedded into the binary
## with `staticRead` while compiling, so nothing is read from disk at runtime
## and the library behaves identically from any working directory.
##
## The sources are only turned into tables when something actually asks for
## them, via the `initExtras` singleton. Programs that import Valido with
## `-d:validoExtras` but never validate a country or a SWIFT code never pay
## the parsing cost.
##
## This module compiles to nothing unless `-d:validoExtras` is defined.

when defined(validoExtras):

  import std/[algorithm, os, sets, strutils, tables]
  import pkg/openparser/yaml

  const dataRoot = currentSourcePath().parentDir / "data" / "countries"

  type
    RawData* = tuple[code, content: string]
      ## A country code paired with the raw YAML embedded at compile time.

    CountryInfo* = object
      ## Mirrors the `info` block of an `info.yml` file.
      short*, long*, alpha2*, alpha3*, iso*, ioc*, capital*, tld*: string

    CountryCurrency* = object
      ## Mirrors the `currency` block of an `info.yml` file.
      code*, name*, symbol*: seq[string]

    CountryPhone* = object
      ## Mirrors the `phone` block of an `info.yml` file.
      code*: seq[string]
      length*: seq[int]
      mobile_prefix*: seq[int]

    CountryPostal* = object
      ## Mirrors the `postal` block of an `info.yml` file.
      description*, redenundant_chars*, regex*, charset*: string
      length*: seq[string]
      formats*: seq[string]

    CountryRecord* = object
      ## One parsed `info.yml` document.
      info*: CountryInfo
      languages*: seq[string]
      currency*: CountryCurrency
      phone*: CountryPhone
      postal*: CountryPostal
      states*: Table[string, string]

    SwiftRecord* = object
      ## One parsed `swift.yml` entry. `branch` is empty when the source
      ## records an explicit `null`.
      name*, city*, branch*, swift*: string

    Extras* = object
      ## The parsed reference tables shared by every extras validator.
      countries*: Table[string, CountryRecord]
      swiftBanks*: Table[string, SwiftRecord]
      swiftCodes*: HashSet[string]

  proc collect(fileName: string): seq[RawData] =
    ## Compile-time only. Embeds every `fileName` under the country tree,
    ## keyed by the ISO 3166-1 alpha-2 directory it came from.
    ##
    ## Sorted so the generated table order does not depend on the order the
    ## filesystem happens to hand back entries.
    var paths: seq[string] = @[]
    for path in walkDirRec(dataRoot):
      if path.extractFilename == fileName:
        paths.add(path)
    paths.sort()
    for path in paths:
      result.add((path.parentDir().extractFilename.toUpperAscii, staticRead(path)))

  const
    countrySources* = collect("info.yml")
    swiftSources* = collect("swift.yml")

  var
    extras: Extras
    extrasReady = false

  proc initExtras*(): Extras =
    ## Returns the shared country and SWIFT reference tables.
    ##
    ## Parsing the embedded YAML is done exactly once, on the first call;
    ## every later call returns the same tables. Roughly 0.4s on the first
    ## call in a release build, and noticeably slower in a debug build.
    if extrasReady:
      return extras

    var countries = initTable[string, CountryRecord]()
    for source in countrySources:
      # A malformed country must not take the whole table down with it.
      try:
        countries[source.code] = parseYAML(source.content, CountryRecord)
      except CatchableError: discard

    var
      banks = initTable[string, SwiftRecord]()
      codes = initHashSet[string]()

    for source in swiftSources:
      try:
        for bank in parseYAML(source.content, seq[SwiftRecord]):
          if bank.swift.len == 0: continue
          codes.incl(bank.swift)
          if not banks.hasKey(bank.swift):
            banks[bank.swift] = bank
      except CatchableError: discard

    extras = Extras(countries: countries, swiftBanks: banks, swiftCodes: codes)
    extrasReady = true
    return extras
