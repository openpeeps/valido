# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

import std/[strutils, unicode]
import ./utils/idna
import ./utils/suffixes
import ./utils/tlds

proc inSorted(list: openArray[string], key: string): bool =
  ## Binary search over a sorted list of domain names. `GetTLDs` and
  ## `GetPublicSuffixes` are both sorted, which a linear scan of 1500 strings
  ## would get right but a request path would feel.
  var
    low = 0
    high = list.len - 1
  while low <= high:
    let mid = (low + high) div 2
    let entry = list[mid]
    if entry == key: return true
    elif entry < key: low = mid + 1
    else: high = mid - 1
  false

proc isKnownTld(input: string): bool =
  ## Whether `input` is a known Top-Level Domain. The input is already in ASCII
  ## form, so an internationalized TLD shows up as its `xn--` encoding.
  input.len > 0 and GetTLDs.inSorted(input.toUpperAscii)

proc isKnownSuffix(input: string): bool =
  ## Whether `input` is a known multi-label public suffix, such as `co.uk`.
  input.len > 0 and GetPublicSuffixes.inSorted(input.toLowerAscii)

proc hasNonAscii(input: string): bool =
  for ch in input:
    if ch.uint8 >= 0x80: return true
  false

proc isValidRepertoire(input: string, allowUnderscore: bool): bool =
  ## Whether every code point of a domain name is one that IDNA2008 allows.
  ## UTS #46 happily accepts symbols, punctuation and emoji, which no registry
  ## will register, so a strict check rejects them here.
  let unicodeForm = toUnicode(input, useStd3 = not allowUnderscore)
  if unicodeForm.len == 0: return false
  for r in unicodeForm.runes:
    if allowUnderscore and r.int32 == '_'.ord: continue
    if r.isExcludedByIdna2008: return false
  true

proc isValidLabel(input: string, allowUnderscore: bool): bool =
  ## Checks the label syntax of RFC 1123: letters, digits and hyphens, no
  ## hyphen at either end, and at most 63 characters.
  if input.len == 0 or input.len > MaxLabelLength: return false
  if input[0] == '-' or input[^1] == '-': return false
  for ch in input:
    if ch in {'a'..'z', 'A'..'Z', '0'..'9', '-'}: continue
    if ch == '_' and allowUnderscore: continue
    return false
  true

proc isDomainName(input: string, minLabels, maxLabels: int, checkTld: bool,
                  isWildcard, allowUnderscore, strict: bool): bool =
  ## Shared implementation of `isDomain` and `isSubDomain`, on a domain name
  ## that has already been converted to ASCII by `toAscii`.
  let labels = input.split('.')
  if labels.len < minLabels or labels.len > maxLabels: return false
  for label in labels:
    if not isValidLabel(label, allowUnderscore): return false
  # A name made of plain ASCII labels cannot hold a code point that IDNA2008
  # excludes, so the Unicode form only has to be built for an IDN.
  if strict and ("xn--" in input or hasNonAscii(input)) and
      not isValidRepertoire(input, allowUnderscore): return false
  if not checkTld: return true
  # Every name ends in a known suffix, which is either a single label Top-Level
  # Domain or one of the multi-label public suffixes that country code TLDs
  # delegate to.
  if labels.len > 2 and isKnownSuffix(labels[^2] & "." & labels[^1]):
    return true
  isKnownTld(labels[^1])

type DomainName = tuple[ascii: string, ok: bool]

proc toDomainName(input: string, transitional, allowUnderscore,
                  strict: bool): DomainName =
  ## Converts a domain name to its ASCII form with UTS #46, reporting whether
  ## it could be processed at all. Shared by `isDomain` and `isSubDomain`.
  ##
  ## `allowUnderscore` relaxes the STD3 ASCII rules so that service labels
  ## survive UTS #46, the narrower label syntax check still applies afterwards.
  let ascii = toAscii(input, transitional = transitional,
                      checkHyphens = true,
                      checkBidi = strict,
                      checkJoiners = strict,
                      useStd3 = not allowUnderscore)
  (ascii, ascii.len > 0)

proc isDomain*(input: string, checkTld = true, transitional = false,
               allowUnderscore = false, allowWildcard = false,
               allowTrailingDot = false, strict = true): bool =
  ## Validates a domain name with its Top-Level Domain, that is a name made of
  ## exactly two labels such as ``example.com``.
  ##
  ## The name is processed with UTS #46 (see `toAscii`), so internationalized
  ## names are accepted in both Unicode and Punycode form:
  ##
  ## ```nim
  ## isDomain("example.com")      # true
  ## isDomain("münchen.de")       # true
  ## isDomain("xn--mnchen-3ya.de") # true
  ## isDomain("sub.example.com")  # false, see `isSubDomain`
  ## isDomain("exam ple.com")     # false
  ## isDomain("example.invalid")  # false
  ## ```
  ##
  ## Set `checkTld` to `false` to accept any syntactically valid suffix, which
  ## is what you want for an internal network or a TLD that `GetTLDs` does not
  ## know about. Set `allowUnderscore` for service labels such as
  ## ``_dmarc.example.com``, `allowWildcard` to accept a leading ``*.``, and
  ## `allowTrailingDot` to accept a fully qualified name ending with a root
  ## dot.
  ##
  ## Set `transitional` to apply the deprecated UTS #46 transitional
  ## processing, where ``ß`` maps to ``ss`` instead of being kept.
  ##
  ## `strict` decides how close to IDNA2008 the name has to be. On top of the
  ## contextual right-to-left and joiner rules of UTS #46, a strict check also
  ## rejects the code points that IDNA2008 excludes even though UTS #46 allows
  ## them, such as symbols and emoji:
  ##
  ## ```nim
  ## isDomain("example.com")     # true
  ## isDomain("xn--ls8h.com")    # false, an emoji label
  ## isDomain("xn--ls8h.com", strict = false) # true, plain UTS #46
  ## ```
  ## Turning `strict` off is cheaper, but admits names a browser or a registry
  ## would reject.
  if input.len == 0: return false
  var
    name = input
    isWildcard = false
  if name[^1] == '.':
    # The root label of a fully qualified name is not part of the name.
    if not allowTrailingDot: return false
    name = name[0 ..< name.len - 1]
  if name.startsWith("*."):
    if not allowWildcard: return false
    isWildcard = true
    name = name[2 .. ^1]
  let (ascii, ok) = name.toDomainName(transitional, allowUnderscore, strict)
  if not ok: return false
  isDomainName(ascii, 2, 2, checkTld, isWildcard, allowUnderscore, strict)

proc isSubDomain*(input: string, checkTld = true, transitional = false,
                  allowUnderscore = false, allowWildcard = false,
                  allowTrailingDot = false, strict = true): bool =
  ## Validates a domain name that has a parent domain, that is a name made of
  ## three labels or more such as ``sub.example.com``.
  ##
  ## Unlike `isDomain` this also accepts the multi-label public suffixes that
  ## country code TLDs delegate to:
  ##
  ## ```nim
  ## isSubDomain("sub.example.com")  # true
  ## isSubDomain("a.b.example.com")   # true
  ## isSubDomain("example.com")       # false, see `isDomain`
  ## isSubDomain("example.co.uk")     # true
  ## isSubDomain("münchen.example")   # true
  ## ```
  ##
  ## The flags work the same way as in `isDomain`, with `allowUnderscore`
  ## covering the whole name.
  if input.len == 0: return false
  var
    name = input
    isWildcard = false
  if name[^1] == '.':
    # The root label of a fully qualified name is not part of the name.
    if not allowTrailingDot: return false
    name = name[0 ..< name.len - 1]
  if name.startsWith("*."):
    if not allowWildcard: return false
    isWildcard = true
    name = name[2 .. ^1]
  let (ascii, ok) = name.toDomainName(transitional, allowUnderscore, strict)
  if not ok: return false
  isDomainName(ascii, 3, high(int), checkTld, isWildcard, allowUnderscore,
                strict)