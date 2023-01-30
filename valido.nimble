# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "A library of string validators and sanitizers."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.10"
requires "bigints"

task dev, "dev":
  echo "\n✨ Compiling..." & "\n"
  exec "nim c --gc:arc --out:bin/valido src/valido.nim"