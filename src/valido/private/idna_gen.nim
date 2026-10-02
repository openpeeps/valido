# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Generator for `src/valido/utils/idna_table.nim`.
##
## Reads the Unicode IDNA data files and emits the compact, compile-time
## lookup tables used by `src/valido/utils/idna.nim` to implement UTS #46
## (Unicode IDNA Compatibility Processing).
##
## The raw Unicode files are cached under `private/data/idna` and downloaded
## from unicode.org on demand, so only the generated Nim file is committed.
##
## Run it with `clue task genidna`.

import std/[algorithm, httpclient, os, sequtils, strformat, strutils,
               tables, unicode]

const
  ## Version of the Unicode Standard the tables are generated from.
  unicodeVersion = "18.0.0"

  prologue = """
# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Compile-time embedded UTS #46 tables. Auto-generated, do not modify.
##
## Run `clue task genidna` to regenerate this file from the Unicode
## Character Database. See `src/valido/private/idna_gen.nim`.

type
  IdnaStatus* = enum
    ## Status of a code point in the IDNA Mapping Table.
    idnaValid, idnaIgnored, idnaMapped, idnaDeviation, idnaDisallowed,
    idnaStd3Valid, idnaStd3Mapped

  JoiningType* = enum
    ## Joining type of a code point, as derived in
    ## `extracted/DerivedJoiningType.txt`.
    jtNone, jtRight, jtLeft, jtDual, jtCausing, jtTransparent

const
"""

  dataDir = currentSourcePath().parentDir / "data" / "idna"
  outFile = currentSourcePath().parentDir.parentDir / "utils" / "idna_table.nim"

  idnaUrl = "https://www.unicode.org/Public/" & unicodeVersion & "/idna/"
  ucdUrl = "https://www.unicode.org/Public/" & unicodeVersion & "/ucd/"

type
  IdnaStatus = enum
    ## Must stay in sync with `IdnaStatus` in the generated module.
    isValid, isIgnored, isMapped, isDeviation, isDisallowed, isStd3Valid,
    isStd3Mapped

  Entry = object
    lo, hi: int
    status: IdnaStatus
    mapping: string
    ## Rune string this code point maps to, empty when there is no mapping.
    idna2008: bool
    ## Whether IDNA2008 excludes the code point even though UTS #46 maps it to
    ## itself, that is the NV8 and XV8 columns of the mapping table.

  JoiningType = enum
    ## Must stay in sync with `JoiningType` in the generated module.
    jtNone, jtRight, jtLeft, jtDual, jtCausing, jtTransparent

proc download(name, url: string): string =
  ## Reads a Unicode data file, caching it locally.
  let path = dataDir / name
  if fileExists(path):
    return readFile(path)
  echo "downloading ", url
  let body = newHttpClient().get(url).body
  createDir(dataDir)
  writeFile(path, body)
  body

proc dataLines(text: string): seq[string] =
  ## Yields the meaningful lines of a UCD data file.
  for line in text.splitLines():
    let stripped = line.split('#')[0].strip()
    if stripped.len > 0:
      result.add stripped

proc parseStatus(field: string): IdnaStatus =
  case field
  of "valid": isValid
  of "ignored": isIgnored
  of "mapped": isMapped
  of "deviation": isDeviation
  of "disallowed": isDisallowed
  of "disallowed_STD3_valid": isStd3Valid
  of "disallowed_STD3_mapped": isStd3Mapped
  else: raise newException(ValueError, "unknown IDNA status: " & field)

proc parseCodePoints(field: string): seq[Rune] =
  if field.len == 0: return
  for hex in strutils.splitWhitespace(field):
    result.add Rune(parseHexInt(hex).int32)

proc parseMappingTable(text: string): seq[Entry] =
  ## Parses `IdnaMappingTable.txt`.
  for line in dataLines(text):
    let
      fields = line.split(';').mapIt(it.strip())
      bounds = fields[0].split("..")
    var entry = Entry(
      lo: parseHexInt(bounds[0]).int,
      hi: parseHexInt(bounds[^1]).int,
      status: parseStatus(fields[1])
    )
    if fields.len > 2 and fields[2].len > 0:
      for r in parseCodePoints(fields[2]):
        entry.mapping.add $r
    if fields.len > 3 and fields[3] in ["NV8", "XV8"]:
      entry.idna2008 = true
    result.add entry

proc parseBidiBrackets(text: string): seq[uint64] =
  ## Parses `BidiBrackets.txt` into `cp | paired << 21 | kind << 42` records.
  for line in dataLines(text):
    let
      fields = line.split(';').mapIt(it.strip())
      cp = parseHexInt(fields[0]).int32
      paired = parseHexInt(fields[1]).int32
    let kind = if fields[2] == "c": 1'u64 else: 0'u64
    result.add cp.uint64 or (paired.uint64 shl 21) or (kind shl 42)

proc parseJoiningType(text: string): seq[uint64] =
  ## Parses `DerivedJoiningType.txt` into `lo | hi << 21 | kind << 42` records.
  for line in dataLines(text):
    let
      fields = line.split(';').mapIt(it.strip())
      bounds = fields[0].split("..")
      lo = parseHexInt(bounds[0]).uint32
      hi = parseHexInt(bounds[^1]).uint32
      kind = case fields[1]
        of "R": jtRight
        of "L": jtLeft
        of "D": jtDual
        of "C": jtCausing
        of "T": jtTransparent
        else: jtNone
    result.add lo.uint64 or (hi.uint64 shl 21) or (kind.ord.uint64 shl 42)

proc sortByCodePoint(records: var seq[uint64]) =
  ## The Unicode data files group records by property value, so the ranges have
  ## to be sorted before they can be looked up with a binary search.
  records.sort(proc (a, b: uint64): int =
    let
      left = (a and 0x1FFFFF'u64).int32
      right = (b and 0x1FFFFF'u64).int32
    if left < right: -1
    elif left > right: 1
    else: 0
  )

proc mergeEntries(entries: var seq[Entry]) =
  ## Collapses neighbouring ranges that share status and mapping.
  var
    merged: seq[Entry]
    last = -1
  for entry in entries:
    if last >= 0 and merged[last].status == entry.status and
        merged[last].mapping == entry.mapping and
        merged[last].idna2008 == entry.idna2008 and merged[last].hi + 1 == entry.lo:
      merged[last].hi = entry.hi
    else:
      merged.add entry
      inc last
  entries = merged

proc nimEscape(s: string): string =
  ## Escapes a string for use as a Nim string literal.
  for ch in s:
    case ch
    of '"': result.add "\\\""
    of '\\': result.add "\\\\"
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    else: result.add ch

proc writeBlob(f: var File, blob: string) =
  ## Writes the blob as a sequence of string literals joined with `&`, never
  ## splitting a UTF-8 sequence across two lines.
  var
    line = newStringOfCap(96)
    first = true
  for ch in blob.runes:
    line.add nimEscape($ch)
    if line.len >= 96:
      f.write "    ", (if first: "" else: "  "), "\"", line, "\" &\n"
      first = false
      line.setLen 0
  if line.len > 0 or first:
    f.write "    ", (if first: "" else: "  "), "\"", line, "\"\n"

proc generate() =
  echo "Unicode ", unicodeVersion
  var entries = parseMappingTable(download("IdnaMappingTable.txt",
                                           idnaUrl & "IdnaMappingTable.txt"))
  var brackets = parseBidiBrackets(download("BidiBrackets.txt",
                                           ucdUrl & "BidiBrackets.txt"))
  var joining = parseJoiningType(download("DerivedJoiningType.txt",
                                          ucdUrl & "extracted/DerivedJoiningType.txt"))
  mergeEntries(entries)
  sortByCodePoint(brackets)
  sortByCodePoint(joining)

  # Packed status records: lo:21 | hi:21 | status:3 | mapOffset:15 | nv8:1
  var
    blob: string
    offsets = newSeq[int](entries.len)
  for i, entry in entries:
    offsets[i] = blob.len
    blob.add entry.mapping
  if blob.len >= (1 shl 15):
    raise newException(ValueError,
      "mapping blob (" & $blob.len & " bytes) does not fit in 15 bits")

  var
    ranges = newStringOfCap(entries.len * 26)
    lengths = newStringOfCap(entries.len * 3)
    first = true
  for i, entry in entries:
    let packed = entry.lo.uint64 or
                 (entry.hi.uint64 shl 21) or
                 (entry.status.ord.uint64 shl 42) or
                 (offsets[i].uint64 shl 45) or
                 (if entry.idna2008: 1'u64 shl 60 else: 0'u64)
    ranges.add (if first: "0x" else: ", 0x") & toHex(packed, 16) & "'u64"
    first = false
    lengths.add $entry.mapping.runeLen & ","
    if (i + 1) mod 20 == 0 and i + 1 < entries.len:
      lengths.add "\n    "
    if (i + 1) mod 8 == 0 and i + 1 < entries.len:
      ranges.add ",\n    "
      first = true

  echo "  ", entries.len, " status ranges, ", blob.len, " byte mapping blob"
  echo "  ", brackets.len, " bidi brackets, ", joining.len, " joining type ranges"

  var f = open(outFile, fmWrite)
  defer: f.close()
  f.write prologue
  f.write "  idnaUnicodeVersion* = \"", unicodeVersion, "\"\n\n"
  f.write "  idnaStatusCount* = ", $entries.len, "\n\n"
  f.write "  ## Packed ``lo:21 | hi:21 | status:3 | mappingOffset:15 | excluded:1``\n"
  f.write "  ## records, sorted by `lo`. Look them up with a binary search.\n"
  f.write "  ## `excluded` marks the code points that IDNA2008 does not allow.\n"
  f.write "  idnaStatusRanges*: array[idnaStatusCount, uint64] = [\n    ",
          ranges, "\n  ]\n\n"
  f.write "  ## Number of code points in the mapping of each status record.\n"
  f.write "  idnaMapLengths*: array[idnaStatusCount, uint8] = [\n    ", lengths, "\n  ]\n\n"
  f.write "  ## Concatenated mapping values referenced by `idnaStatusRanges`.\n"
  f.write "  idnaMapBlob* =\n"
  writeBlob(f, blob)
  f.write "\n"
  f.write "  idnaBidiBracketCount* = ", $brackets.len, "\n\n"
  f.write "  ## Packed ``cp:21 | paired:21 | kind:2`` records, where ``kind`` is 1\n"
  f.write "  ## for a closing bracket.\n"
  f.write "  idnaBidiBrackets*: array[idnaBidiBracketCount, uint64] = [\n"
  first = true
  for rec in brackets:
    f.write (if first: "" else: ",\n") & "    0x" & toHex(rec, 16) & "'u64"
    first = false
  f.write "\n  ]\n\n"
  f.write "  idnaJoiningTypeCount* = ", $joining.len, "\n\n"
  f.write "  ## Packed ``lo:21 | hi:21 | type:3`` records for every code point\n"
  f.write "  ## that is not `jtNone`, sorted by `lo`.\n"
  f.write "  idnaJoiningTypes*: array[idnaJoiningTypeCount, uint64] = [\n"
  first = true
  for rec in joining:
    f.write (if first: "" else: ",\n") & "    0x" & toHex(rec, 16) & "'u64"
    first = false
  f.write "\n  ]\n"

  echo "wrote ", outFile, " (", getFileSize(outFile), " bytes)"

when isMainModule:
  generate()