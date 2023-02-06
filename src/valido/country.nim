# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

# when defined vCountries:
#   import std/[os, macros, json, jsonutils]
#   macro readCountries() =
#     let path = normalizedPath(currentSourcePath().parentDir().parentDir())
#     let countries = parseJSON(staticRead( path / "stubs" / "countries.json"))
#     echo countries

#   readCountries()

#   type
#     Countries* = enum

#     Country = ref object
#       info: tuple[
#         short, long, alpha2, alpha3, iso,
#         ioc, capital, tld: string
#       ]
#       languages: seq[string]
#       currency: tuple[code, name, symbol: seq[string]]
#       phone: tuple[code, length, prefixes: seq[string]]
#       postal: tuple[
#         description: string,
#         redundant_chars: string,
#         regex: string,
#         length,formats: seq[string]
#       ]
#       states: seq[tuple[a2, name: string]]

#     CountryTable* = TableRef[string, Country]

#   proc getCountryByCapital*(input: string) =
#     discard

#   proc getCurrency*(c: Country): string =
#     result = c.currency

#   proc isMobile*(c: Country, input: string): bool =
#     if input.len == c.phone.length:
#       discard

# TODO