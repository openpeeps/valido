# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

when defined vCountries:
  import std/[os, macros, json, jsonutils]
  macro readCountries() =
    let path = normalizedPath(currentSourcePath().parentDir().parentDir())
    let countries = parseJSON(staticRead( path / "stubs" / "countries.json"))
    echo countries

  readCountries()