# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Conformance harness for UTS #46.
##
## Runs `IdnaTestV2.txt` from the Unicode IDNA data files through `toUnicode`,
## `toAscii` and transitional `toAscii`, and reports the vectors where
## Valido disagrees with the reference results.
##
## Run it with `clue task testidna`. The vectors are not committed, the raw
## file is downloaded into `private/data/idna` by `clue task genidna`.

import std/[httpclient, os, sequtils, strutils, tables, unicode]
import ../utils/idna

const
  testFile = currentSourcePath().parentDir / "data" / "idna" / "IdnaTestV2.txt"

proc downloadTestFile() =
  if fileExists(testFile): return
  echo "downloading IdnaTestV2.txt"
  let body = newHttpClient().get(
    "https://www.unicode.org/Public/idna/latest/IdnaTestV2.txt").body
  createDir(testFile.parentDir)
  writeFile(testFile, body)

proc unescape(s: string): string =
  ## Resolves the ``\\uXXXX`` and ``\\x{XXXX}`` escapes used by the vectors.
  var i = 0
  while i < s.len:
    if s[i] == '\\' and i + 1 < s.len:
      if s[i + 1] == 'u' and i + 5 < s.len:
        result.add $Rune(parseHexInt(s[i + 2 .. i + 5]).int32)
        i += 6
        continue
      if s[i + 1] == 'x' and i + 2 < s.len and s[i + 2] == '{':
        let close = s.find('}', i)
        if close > 0:
          result.add $Rune(parseHexInt(s[i + 3 ..< close]).int32)
          i = close + 1
          continue
    result.add s[i]
    inc i

proc main() =
  downloadTestFile()
  var
    checked = 0
    failures: seq[string]
    counts: Table[string, int]

  for line in readFile(testFile).splitLines():
    var
      raw = line
      comment = ""
    let hash = line.find('#')
    if hash >= 0:
      raw = line[0 ..< hash]
      comment = line[hash + 1 .. ^1].strip()
    var cols = raw.split(';').mapIt(it.strip())
    while cols.len < 7: cols.add ""
    if cols[0].len == 0: continue

    # A blank column means "the same as the previous result", a blank status
    # column means "no errors".
    let
      source = unescape(cols[0])
      rawSource = cols[0]
      expectedUnicode =
        if cols[1].len > 0: unescape(cols[1]) else: source
      unicodeErrors = cols[2].len > 0 and cols[2] != "[]"
      expectedAscii =
        if cols[3].len > 0: unescape(cols[3]) else: expectedUnicode
      asciiErrors = if cols[4].len > 0: cols[4] != "[]" else: unicodeErrors
      expectedTransitional =
        if cols[5].len > 0: unescape(cols[5]) else: expectedAscii
      transitionalErrors =
        if cols[6].len > 0: cols[6] != "[]" else: asciiErrors

    inc checked
    for kind in ["toUnicode", "toAscii", "toAsciiT"]:
      var
        expected: string
        expectError: bool
        value: string
        ok: bool
      if kind == "toUnicode":
        (expected, expectError) = (expectedUnicode, unicodeErrors)
        let (v, o) = tryToUnicode(source)
        (value, ok) = (v, o)
      elif kind == "toAscii":
        (expected, expectError) = (expectedAscii, asciiErrors)
        value = toAscii(source)
        ok = value.len > 0
      else:
        (expected, expectError) = (expectedTransitional, transitionalErrors)
        value = toAscii(source, transitional = true)
        ok = value.len > 0
      if expectError:
        if ok:
          counts.mgetOrPut(kind & " should fail", 0).inc
          failures.add kind & ": expected an error, got " & $value & "  [" & rawSource & "] " & comment
      elif not ok:
        counts.mgetOrPut(kind & " should pass", 0).inc
        failures.add kind & ": expected " & $expected & ", got an error  [" & rawSource & "] " & comment
      elif value != expected:
        counts.mgetOrPut(kind & " mismatch", 0).inc
        failures.add kind & ": expected " & $expected & ", got " & $value &
                   "  [" & rawSource & "] " & comment

  echo "checked ", checked, " vectors, ", failures.len, " disagreements"
  for kind, n in counts: echo "  ", kind, ": ", n
  let limit = if failures.len <= 40: failures.len else: 40
  for i in 0 ..< limit: echo "  - ", failures[i]

when isMainModule:
  main()