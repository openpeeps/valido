# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "A library of string validators and sanitizers."
license       = "MIT"
srcDir        = "src"
skipDirs      = @["data"]

# Dependencies

requires "nim >= 1.6.10"
requires "bigints"
requires "zxcvbn"

task dev, "dev":
  echo "\n✨ Compiling..." & "\n"
  exec "nim c --gc:arc --path:. --out:bin/valido src/valido.nim"

task gen, "generate data":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/gen src/valido/private/csv2yaml.nim"

task genswift, "generate data":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/gen src/valido/private/countries.nim"