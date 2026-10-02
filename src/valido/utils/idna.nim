# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Unicode IDNA Compatibility Processing (UTS #46) for internationalized
## domain names, together with the Punycode codec (RFC 3492) and the NFC
## normalization it builds on.
##
## ``toAscii`` and ``toUnicode`` implement the processing steps from
## <https://unicode.org/reports/tr46#Processing>: every code point is mapped
## with the IDNA Mapping Table, the result is normalized to NFC, broken into
## labels at U+002E, and each label is validated against the validity criteria
## of section 4.1 (NFC, hyphen rules, label separators, leading combining
## marks, code point status, CONTEXTJ, CONTEXTB) before being encoded.
##
## Domain name level rules that are not part of UTS #46 (how many labels a
## name has, whether the TLD is known, wildcards, underscores) live in
## `valido/domain.nim`.
##
## The lookup tables in `./idna_table.nim` are generated from the Unicode
## Character Database by `clue task genidna`.

import std/[strutils, unicode]
import punycode
import unicodedb/compositions
import unicodedb/decompositions
import unicodedb/properties
import ./idna_table

const
  ## Prefix that marks an ASCII Compatible Encoded (ACE) label.
  AcePrefix* = "xn--"
  ## Maximum number of octets in a single domain name label.
  MaxLabelLength* = 63
  ## Maximum number of octets in a domain name, excluding the root label.
  MaxDomainLength* = 253
  ## U+002D HYPHEN-MINUS
  hyphen: char = '-'
  # The only ASCII code points allowed with `UseSTD3ASCIIRules` enabled.
  asciiLdh = {'a'..'z', '0'..'9', '-'}
  # U+002E FULL STOP
  fullStop: char = '.'
  # U+200C ZERO WIDTH NON-JOINER
  zwnj = 0x200C
  # U+200D ZERO WIDTH JOINER
  zwj = 0x200D
  # U+1E9E LATIN CAPITAL LETTER SHARP S, mapped to "ss" only when
  # transitional processing is requested.
  capitalSharpS = 0x1E9E
  # Canonical combining class of U+094D VIRAMA, used by the CONTEXTJ rules.
  viramaCcc = 9
  # Hangul composition constants from The Unicode Standard, chapter 3.12.
  hangulSBase = 0xAC00
  hangulLBase = 0x1100
  hangulVBase = 0x1161
  hangulTBase = 0x11A7
  hangulLCount = 19
  hangulVCount = 21
  hangulTCount = 28
  hangulNCount = hangulVCount * hangulTCount
  hangulSCount = hangulLCount * hangulNCount
  # A combining class above every real one, standing for "no character
  # between the starter and the character being composed".
  noCcc = 256

type
  BidiClass = enum
    ## The Bidi_Class values used by the CONTEXTB rules of RFC 5893.
    bcL, bcR, bcAL, bcAN, bcEN, bcES, bcCS, bcET, bcON, bcBN, bcNSM, bcOther

  IdnaOptions = object
    ## The input flags of UTS #46, section 4.
    transitional: bool
      ## Deprecated transitional processing: maps the four deviation
      ## characters instead of treating them as valid.
    useStd3: bool
      ## Restrict ASCII code points to letters, digits and hyphens.
    checkHyphens: bool
      ## Enforce the hyphen rules of section 4.1.
    checkBidi: bool
      ## Enforce the right-to-left rules of RFC 5893.
    checkJoiners: bool
      ## Enforce the CONTEXTJ rules of RFC 5892, appendix A.
    verifyDnsLength: bool
      ## Verify the label and total length limits of RFC 1034.

# -- UTF-8 --

func isAscii(s: string): bool =
  ## Whether every byte of `s` is a 7 bit ASCII character.
  for ch in s:
    if ch.uint8 >= 0x80: return false
  true

func utf8At(s: string, i: int): tuple[ch: Rune, size: int] =
  ## Decodes the UTF-8 sequence at `i` without validating it.
  let b = ord(s[i])
  if b < 0x80:
    (Rune(b), 1)
  elif b < 0xE0:
    (Rune(((b and 0x1F) shl 6) or (ord(s[i + 1]) and 0x3F)), 2)
  elif b < 0xF0:
    (Rune(((b and 0x0F) shl 12) or ((ord(s[i + 1]) and 0x3F) shl 6) or
          (ord(s[i + 2]) and 0x3F)), 3)
  else:
    (Rune(((b and 0x07) shl 18) or ((ord(s[i + 1]) and 0x3F) shl 12) or
          ((ord(s[i + 2]) and 0x3F) shl 6) or (ord(s[i + 3]) and 0x3F)), 4)

# -- normalization --

func isHangulSyllable(r: Rune): bool {.inline.} =
  let cp = r.int32
  cp >= hangulSBase and cp < hangulSBase + hangulSCount

func isHangulL(r: Rune): bool {.inline.} =
  let cp = r.int32
  cp >= hangulLBase and cp < hangulLBase + hangulLCount

func isHangulV(r: Rune): bool {.inline.} =
  let cp = r.int32
  cp > hangulVBase - 1 and cp < hangulVBase + hangulVCount

func isHangulT(r: Rune): bool {.inline.} =
  let cp = r.int32
  cp > hangulTBase - 1 and cp < hangulTBase + hangulTCount

func isHangulLV(r: Rune): bool {.inline.} =
  isHangulSyllable(r) and (r.int32 - hangulSBase) mod hangulTCount == 0

func hasDecomposition(r: Rune): bool {.inline.} =
  for _ in r.canonicalDecomposition():
    return true
  false

proc decompose(r: Rune, dest: var seq[Rune], depth = 0) =
  ## Appends the full canonical decomposition of `r` to `dest`.
  if isHangulSyllable(r):
    let s = r.int32 - hangulSBase
    dest.add Rune(hangulLBase + s div hangulNCount)
    dest.add Rune(hangulVBase + (s mod hangulNCount) div hangulTCount)
    let t = s mod hangulTCount
    if t != 0: dest.add Rune(hangulTBase + t)
  elif not hasDecomposition(r):
    dest.add r
  elif depth >= 3:
    dest.add r
  else:
    for d in r.canonicalDecomposition():
      decompose(d, dest, depth + 1)

proc canonicalOrder(runes: var seq[Rune]) =
  ## Sorts each run of combining marks by canonical combining class.
  var i = 1
  while i < runes.len:
    let ccc = runes[i].combining()
    if ccc != 0:
      var j = i
      while j > 0:
        let prev = runes[j - 1].combining()
        if prev == 0 or prev <= ccc: break
        swap(runes[j], runes[j - 1])
        dec j
    inc i

func tryCompose(a, b: Rune): (Rune, bool) =
  ## Returns the primary composite of `a` followed by `b`, if there is one.
  if isHangulL(a) and isHangulV(b):
    let index = (a.int32 - hangulLBase) * hangulVCount + (b.int32 - hangulVBase)
    return (Rune(hangulSBase + index * hangulTCount), true)
  if isHangulLV(a) and isHangulT(b):
    return (Rune(a.int32 + b.int32 - hangulTBase), true)
  var composed: Rune
  if composition(composed, a, b):
    return (composed, true)
  (Rune(0), false)

proc compose(runes: seq[Rune]): seq[Rune] =
  ## Applies the canonical composition algorithm of UAX #15 to an already
  ## canonically ordered and decomposed sequence.
  if runes.len == 0: return
  result = newSeqOfCap[Rune](runes.len)
  var
    starterPos = 0
    starterCh = runes[0]
    lastCcc = starterCh.combining()
  result.add starterCh
  # A leading combining mark never blocks composition.
  if lastCcc != 0: lastCcc = noCcc
  for i in 1 ..< runes.len:
    let
      ch = runes[i]
      ccc = ch.combining()
    let (composed, ok) = tryCompose(starterCh, ch)
    # A character composes with the starter unless something of equal or
    # higher combining class stands between them.
    if ok and (lastCcc < ccc or lastCcc == 0):
      result[starterPos] = composed
      starterCh = composed
    else:
      if ccc == 0:
        starterPos = result.len
        starterCh = ch
      lastCcc = ccc
      result.add ch

proc toNfc*(input: string): string =
  ## Normalizes `input` to Unicode Normalization Form C (NFC).
  ##
  ## Sequences of Hangul jamo are composed, everything else follows the
  ## canonical decomposition and composition algorithm of UAX #15. ASCII
  ## input is already normalized and is returned untouched.
  if input.len == 0 or input.isAscii: return input
  # A string is in NFC form when no character may need reordering or
  # recomposition (NFC_QC) and no character has a canonical decomposition.
  # The quick check alone is not enough: characters that are excluded from
  # composition, such as U+0344 or U+212B, are reported as NFC_QC=No even
  # though composing their decomposition yields a different character.
  var quick = true
  for r in input.runes:
    if (r.quickCheck() and int(nfcQcNo)) == 0 or hasDecomposition(r):
      quick = false
      break
  if quick: return input
  var
    source: seq[Rune]
    decomposed: seq[Rune]
  source.setLen 0
  for r in input.runes: source.add r
  decomposed = newSeqOfCap[Rune](source.len * 2)
  for r in source: decompose(r, decomposed)
  canonicalOrder(decomposed)
  let composed = compose(decomposed)
  result = newStringOfCap(input.len)
  for r in composed: result.add $r

proc isNfc*(input: string): bool =
  ## Returns `true` when `input` is in Unicode Normalization Form C.
  toNfc(input) == input

# -- punycode --

proc punycodeEncode*(label: string): string =
  ## Encodes a U-label as an ACE label, prefixed with ``xn--``.
  ## Returns `""` when the label cannot be encoded.
  if label.isAscii: return ""
  try:
    result = punycode.encode(AcePrefix, label)
  except PunyError:
    result = ""

proc punycodeDecode*(label: string): string =
  ## Decodes an ACE label, with or without the ``xn--`` prefix, into its
  ## U-label. Returns `""` when the label cannot be decoded.
  result = label
  if result.toLowerAscii.startsWith(AcePrefix):
    if result.len == AcePrefix.len: return ""
    result = result[AcePrefix.len .. ^1]
  try:
    result = punycode.decode(result)
  except PunyError:
    result = ""

proc isAce*(label: string): bool =
  ## Returns `true` when `label` is an ASCII Compatible Encoding (ACE), that is
  ## a label carrying the ``xn--`` prefix.
  label.len > AcePrefix.len and label.toLowerAscii.startsWith(AcePrefix)

# -- the IDNA mapping table --

func findStatus(cp: Rune): int =
  ## Binary searches `idnaStatusRanges`, returning `-1` when `cp` is not listed.
  var
    low = 0
    high = idnaStatusCount - 1
  while low <= high:
    let
      mid = (low + high) div 2
      rec = idnaStatusRanges[mid]
      first = (rec and 0x1FFFFF'u64).int32
      last = ((rec shr 21) and 0x1FFFFF'u64).int32
    if cp.int32 < first: high = mid - 1
    elif cp.int32 > last: low = mid + 1
    else: return mid
  -1

proc idnaStatus*(cp: Rune): IdnaStatus =
  ## The status of `cp` in the IDNA Mapping Table. Code points that the table
  ## does not list are `idnaDisallowed`.
  let index = findStatus(cp)
  if index < 0: return idnaDisallowed
  IdnaStatus((idnaStatusRanges[index] shr 42) and 0x7'u64)

proc isExcludedByIdna2008*(cp: Rune): bool =
  ## Whether IDNA2008 (RFC 5892) excludes `cp` from every domain name, even
  ## though UTS #46 leaves it valid. These are the `NV8` and `XV8` columns of the
  ## IDNA Mapping Table: symbols, punctuation, emoji, unassigned and Hangul jamo
  ## among others. No implementation of UTS #46 is obliged to reject them, but
  ## no registry will hand them out either.
  let index = findStatus(cp)
  if index < 0: return true
  (idnaStatusRanges[index] and (1'u64 shl 60)) != 0

proc idnaMapping*(cp: Rune): string =
  ## The value `cp` maps to in the IDNA Mapping Table, or `""` when the mapping
  ## is empty or absent.
  let index = findStatus(cp)
  if index < 0: return ""
  let count = int(idnaMapLengths[index])
  if count == 0: return ""
  let offset = int((idnaStatusRanges[index] shr 45) and 0x7FFF'u64)
  result = newStringOfCap(count * 4)
  var pos = offset
  for _ in 0 ..< count:
    let (ch, size) = utf8At(idnaMapBlob, pos)
    result.add $ch
    pos += size

proc isBidiDomainName(domain: string): bool =
  ## A Bidi domain name contains at least one character with Bidi_Class R, AL
  ## or AN, see RFC 5893 section 1.4.
  for r in domain.runes:
    case r.bidirectional()
    of "R", "AL", "AN": return true
    else: discard
  false

proc bidiClass(r: Rune): BidiClass =
  case r.bidirectional()
  of "L": bcL
  of "R": bcR
  of "AL": bcAL
  of "AN": bcAN
  of "EN": bcEN
  of "ES": bcES
  of "CS": bcCS
  of "ET": bcET
  of "ON": bcON
  of "BN": bcBN
  of "NSM": bcNSM
  else: bcOther

func bracket(cp: Rune): tuple[paired: Rune, closing: bool, found: bool] =
  ## Looks up the bidirectional paired bracket of `cp`.
  var
    low = 0
    high = idnaBidiBracketCount - 1
  while low <= high:
    let mid = (low + high) div 2
    let rec = idnaBidiBrackets[mid]
    let value = (rec and 0x1FFFFF'u64).int32
    if cp.int32 < value: high = mid - 1
    elif cp.int32 > value: low = mid + 1
    else:
      return (Rune((rec shr 21) and 0x1FFFFF'u64),
              ((rec shr 42) and 0x3'u64) == 1, true)
  (Rune(0), false, false)

func joiningType(cp: Rune): JoiningType =
  ## The joining type of `cp`, `jtNone` for every code point that is not
  ## listed in `extracted/DerivedJoiningType.txt`.
  var
    low = 0
    high = idnaJoiningTypeCount - 1
  while low <= high:
    let mid = (low + high) div 2
    let
      rec = idnaJoiningTypes[mid]
      first = (rec and 0x1FFFFF'u64).int32
      last = ((rec shr 21) and 0x1FFFFF'u64).int32
    if cp.int32 < first: high = mid - 1
    elif cp.int32 > last: low = mid + 1
    else: return JoiningType((rec shr 42) and 0x7'u64)
  jtNone

func isJoiningPairable(t: JoiningType): bool {.inline.} =
  ## Whether a character of joining type `t` may sit at either end of a
  ## joining sequence, that is L, D, R or ZWNJ.
  t in {jtLeft, jtDual, jtRight}

# -- validity criteria --

proc validContextJ(runes: seq[Rune]): bool =
  ## The CONTEXTJ rules of RFC 5892, appendix A.
  for i in 0 ..< runes.len:
    let cp = runes[i].int32
    if cp != zwnj and cp != zwj: continue
    # Rule A.1 / B.1: preceded by a virama. This also rules out a joiner in
    # first position, which has nothing to be preceded by.
    if i > 0 and runes[i - 1].combining() == viramaCcc: continue
    if cp == zwj: return false
    # Rule A.2: (L | D) T* ZWNJ T* (R | D)
    var
      before = i - 1
      validBefore = false
    while before >= 0:
      let kind = joiningType(runes[before])
      if kind == jtTransparent:
        dec before
      else:
        validBefore = kind in {jtLeft, jtDual}
        break
    if not validBefore: return false
    var after = i + 1
    while after < runes.len and joiningType(runes[after]) == jtTransparent:
      inc after
    if after >= runes.len: return false
    if not isJoiningPairable(joiningType(runes[after])): return false
  true

proc validBrackets(runes: seq[Rune]): bool =
  ## The bidirectional bracket rules, as referenced by RFC 5893 section 2.
  var stack: seq[Rune]
  for i, r in runes:
    let (paired, closing, found) = bracket(r)
    if not found: continue
    if not closing:
      # An opening bracket must follow a strong character, otherwise the
      # surrounding text direction is ambiguous.
      if i > 0:
        let previous = bidiClass(runes[i - 1])
        if previous != bcL and previous != bcR: return false
      stack.add paired
    elif stack.len > 0:
      if stack[^1] != r: return false
      stack.setLen(stack.len - 1)
  stack.len == 0

proc validBidi(runes: seq[Rune]): bool =
  ## The six right-to-left conditions of RFC 5893, section 2.
  if runes.len == 0: return false
  let
    first = bidiClass(runes[0])
    rtl = first in {bcR, bcAL}
  if first != bcL and not rtl: return false
  var
    hasEn = false
    hasAn = false
  for r in runes:
    let kind = bidiClass(r)
    if rtl:
      if kind notin {bcR, bcAL, bcAN, bcEN, bcES, bcCS, bcET, bcON, bcBN,
                     bcNSM}: return false
    else:
      if kind notin {bcL, bcEN, bcES, bcCS, bcET, bcON, bcBN, bcNSM}:
        return false
    if kind == bcEN: hasEn = true
    elif kind == bcAN: hasAn = true
  # An RTL label may not mix European and Arabic numbers.
  if rtl and hasEn and hasAn: return false
  # Both label kinds must end in a strong character, ignoring trailing marks.
  var last = runes.len - 1
  while last >= 0 and bidiClass(runes[last]) == bcNSM: dec last
  if last < 0: return false
  let
    kind = bidiClass(runes[last])
    allowed = if rtl: {bcR, bcAL, bcEN, bcAN} else: {bcL, bcEN}
  if kind notin allowed: return false
  validBrackets(runes)

proc validLabel(label: string, opts: IdnaOptions, checkNfc,
                checkBidiDomain: bool): bool =
  ## The validity criteria of UTS #46, section 4.1.
  ##
  ## `checkNfc` is only needed for labels that came out of Punycode, since every
  ## other label has already been normalized as part of the whole domain name.
  ## `checkBidiDomain` mirrors the CheckBidi flag, which only applies to right
  ## to left domain names.
  var runes: seq[Rune]
  for r in label.runes: runes.add r
  if runes.len == 0: return false
  if checkNfc and not isNfc(label): return false
  if opts.checkHyphens:
    if label.len >= 4 and label[2] == hyphen and label[3] == hyphen: return false
    if label[0] == hyphen or label[^1] == hyphen: return false
  elif label.toLowerAscii.startsWith(AcePrefix):
    return false
  for r in runes:
    if r.int32 == fullStop.ord: return false
  # A label may not begin with a combining mark.
  if runes[0].unicodeCategory() in ctgM: return false
  for r in runes:
    # Mapping already ran, so an ASCII code point that survives is one of the
    # code points the STD3 ASCII rules allow. Checking that here saves a lookup
    # in the mapping table for every character of a plain ASCII label.
    if r.int32 < 0x80:
      if opts.useStd3 and char(r.int32) notin asciiLdh: return false
      continue
    case idnaStatus(r)
    of idnaValid, idnaDeviation:
      discard
    of idnaStd3Valid, idnaStd3Mapped:
      # The STD3 statuses only exist in tables older than Unicode 16.
      if opts.useStd3: return false
    of idnaMapped, idnaIgnored, idnaDisallowed:
      return false
  if opts.checkJoiners and not validContextJ(runes): return false
  if opts.checkBidi and checkBidiDomain and not validBidi(runes): return false
  true

# -- processing --

proc mapDomain(input: string, opts: IdnaOptions): string =
  ## Step 1 of UTS #46: map every code point with the IDNA Mapping Table.
  result = newStringOfCap(input.len)
  for r in input.runes:
    case idnaStatus(r)
    of idnaValid:
      result.add $r
    of idnaIgnored:
      discard
    of idnaMapped:
      if opts.transitional and r.int32 == capitalSharpS:
        result.add "ss"
      else:
        result.add idnaMapping(r)
    of idnaDeviation:
      if opts.transitional: result.add idnaMapping(r)
      else: result.add $r
    of idnaStd3Mapped:
      # A code point that is only disallowed by the STD3 ASCII rules still maps
      # when those rules are not enforced.
      if opts.useStd3: result.add $r
      else: result.add idnaMapping(r)
    of idnaDisallowed, idnaStd3Valid:
      # Disallowed code points are left in place, section 4.1 rejects them.
      result.add $r

proc processLabels(input: string, opts: IdnaOptions):
    tuple[value: string, ok: bool] =
  ## Steps 2 to 4 of UTS #46. Returns the domain name in Unicode form.
  let
    mapped = mapDomain(input, opts)
    normalized = toNfc(mapped)
    labels = normalized.split(fullStop)
  var
    values = newSeqOfCap[string](labels.len)
    wasAce = newSeqOfCap[bool](labels.len)
  result.ok = true
  for i, label in labels:
    # The root label of a fully qualified name is empty and allowed, any
    # other empty label is not.
    if label.len == 0:
      if i + 1 != labels.len:
        result.ok = false
        return
      values.add label
      wasAce.add false
      continue
    if not label.startsWith(AcePrefix):
      values.add label
      wasAce.add false
      continue
    # An ACE label is converted back to Unicode without being mapped again.
    var
      unicodeLabel: seq[Rune]
      pureAscii = true
    for r in label.runes:
      if r.int32 > 0x7F: pureAscii = false
    if not pureAscii:
      result.ok = false
      return
    try:
      for r in punycode.decode(
          if label.len == AcePrefix.len: "" else: label[AcePrefix.len .. ^1]
        ).runes:
        unicodeLabel.add r
    except PunyError:
      discard
    # An empty or all ASCII payload is not a valid A-label.
    var payloadIsAscii = true
    for r in unicodeLabel:
      if r.int32 > 0x7F: payloadIsAscii = false
    if unicodeLabel.len == 0 or payloadIsAscii:
      result.ok = false
      return
    values.add $unicodeLabel
    wasAce.add true

  # The right-to-left rules only apply to a Bidi domain name, which has to be
  # decided once every label has been converted back to Unicode.
  let checkBidiDomain = opts.checkBidi and isBidiDomainName(values.join("."))
  result.value = newStringOfCap(normalized.len)
  for i, value in values:
    if value.len > 0:
      # A label that came out of Punycode is validated as nontransitional, so
      # that a deviation character can be written as Punycode during a
      # transition.
      let labelOptions =
        if wasAce[i]:
          IdnaOptions(useStd3: opts.useStd3,
                      checkHyphens: opts.checkHyphens,
                      checkBidi: opts.checkBidi,
                      checkJoiners: opts.checkJoiners)
        else: opts
      if not validLabel(value, labelOptions, checkNfc = wasAce[i],
                        checkBidiDomain = checkBidiDomain):
        result.ok = false
        return
    result.value.add value
    if i + 1 != values.len: result.value.add '.'

proc toUnicode*(input: string, transitional = false, checkHyphens = true,
                checkBidi = true, checkJoiners = true,
                useStd3 = true): string =
  ## Converts an internationalized domain name to its Unicode form, as defined
  ## by `ToUnicode` in <https://unicode.org/reports/tr46#ToUnicode>.
  ##
  ## Accepts both ACE (``xn--``) and Unicode labels, maps and normalizes them,
  ## and returns the result in Unicode form. Returns `""` when the domain name
  ## is invalid, since a valid domain name is never empty.
  ##
  ## Set `transitional` to apply the deprecated transitional processing, where
  ## the four deviation characters are mapped instead of kept. Nontransitional
  ## processing is what the DNS currently expects.
  ##
  ## The remaining flags are the input flags of UTS #46: `checkHyphens` for the
  ## label hyphen rules, `checkBidi` for the right-to-left rules of RFC 5893,
  ## `checkJoiners` for the CONTEXTJ rules of RFC 5892, and `useStd3` to
  ## restrict ASCII to letters, digits and hyphens. Turning them off makes the
  ## processing more permissive, not more correct.
  processLabels(input, IdnaOptions(
    transitional: transitional,
    useStd3: useStd3,
    checkHyphens: checkHyphens,
    checkBidi: checkBidi,
    checkJoiners: checkJoiners
  )).value

proc tryToUnicode*(input: string, transitional = false, checkHyphens = true,
                   checkBidi = true, checkJoiners = true,
                   useStd3 = true): (string, bool) =
  ## Like `toUnicode`, but also reports whether the domain name was valid.
  let processed = processLabels(input, IdnaOptions(
    transitional: transitional,
    useStd3: useStd3,
    checkHyphens: checkHyphens,
    checkBidi: checkBidi,
    checkJoiners: checkJoiners
  ))
  if not processed.ok: return ("", false)
  (processed.value, true)

proc toAscii*(input: string, transitional = false, verifyDnsLength = true,
              checkHyphens = true, checkBidi = true, checkJoiners = true,
              useStd3 = true): string =
  ## Converts an internationalized domain name to its ASCII form, as defined by
  ## `ToASCII` in <https://unicode.org/reports/tr46#ToASCII>.
  ##
  ## Every label that is not already ASCII is encoded as Punycode and prefixed
  ## with ``xn--``. Returns `""` when the domain name is invalid.
  ##
  ## Set `transitional` to apply the deprecated transitional processing,
  ## `verifyDnsLength` to enforce the 63 octet label and 253 octet domain name
  ## limits of RFC 1034, and see `toUnicode` for the remaining flags.
  let processed = processLabels(input, IdnaOptions(
    transitional: transitional,
    useStd3: useStd3,
    checkHyphens: checkHyphens,
    checkBidi: checkBidi,
    checkJoiners: checkJoiners
  ))
  if not processed.ok: return ""
  let labels = processed.value.split(fullStop)
  var asciiForm = newStringOfCap(processed.value.len)
  for i, label in labels:
    if verifyDnsLength:
      # The empty root label of a fully qualified name is only tolerated when
      # the DNS length restrictions are not verified.
      if label.len == 0: return ""
      if label.len > MaxLabelLength: return ""
    if label.isAscii:
      asciiForm.add label
    else:
      let encoded = punycodeEncode(label)
      if encoded.len == 0: return ""
      if verifyDnsLength and encoded.len > MaxLabelLength: return ""
      asciiForm.add encoded
    if i + 1 != labels.len: asciiForm.add '.'
  if verifyDnsLength and asciiForm.len > MaxDomainLength: return ""
  asciiForm

proc tryToAscii*(input: string, transitional = false, verifyDnsLength = true,
                 checkHyphens = true, checkBidi = true, checkJoiners = true,
                 useStd3 = true): (string, bool) =
  ## Like `toAscii`, but also reports whether the domain name was valid.
  let value = toAscii(input, transitional, verifyDnsLength, checkHyphens,
                      checkBidi, checkJoiners, useStd3)
  (value, value.len > 0)

proc isIdn*(input: string, transitional = false, verifyDnsLength = true,
            checkHyphens = true, checkBidi = true, checkJoiners = true,
            useStd3 = true): bool =
  ## Returns `true` when `input` is a domain name that can be processed under
  ## UTS #46, in either Unicode or ACE form.
  toAscii(input, transitional, verifyDnsLength, checkHyphens, checkBidi,
          checkJoiners, useStd3).len > 0