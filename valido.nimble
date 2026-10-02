# Package

version       = "0.1.3"
author        = "George Lemon"
description   = "A library of string validators and sanitizers."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 2.0.0"
requires "bigints >= 0.1.0"
requires "blackpaper >= 0.1.0"
requires "openparser >= 0.2.0"
requires "punycode >= 0.1.0"
requires "unicodedb >= 0.14.0"

# The extras API is gated on the `validoExtras` compiler define. This feature
# exists so build tools that can only pass nimble features (clue, for example)
# can still switch it on: `clue build --features:extras`.
feature "extras":
  switch("define", "validoExtras")

task dev, "dev":
  echo "\n✨ Compiling..." & "\n"
  exec "nim c --gc:arc --path:. --out:bin/valido src/valido.nim"

task gen, "generate data":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/gen src/valido/private/csv2yaml.nim"

task genswift, "generate data":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/gen src/valido/private/countries.nim"

task genidna, "generate the UTS #46 tables":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/genidna src/valido/private/idna_gen.nim"

task testidna, "run the UTS #46 conformance vectors":
  exec "nim c -d:release --opt:speed --gc:arc --out:bin/testidna src/valido/private/idna_test.nim"
