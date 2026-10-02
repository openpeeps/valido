# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Unicode IDNA Compatibility Processing (UTS #46), Punycode and NFC.
##
## Re-exports `valido/utils/idna.nim` so that the whole IDNA API is available
## from a single `import valido`.
##
## ``isDomain`` and ``isSubDomain`` in `valido/domain.nim` build on top of it.

import ./utils/idna
import ./utils/idna_table

export isAce, idnaMapping, idnaStatus, isExcludedByIdna2008, isIdn,
       isNfc, punycodeDecode,
       punycodeEncode, toAscii, toNfc, toUnicode, tryToAscii, tryToUnicode
export IdnaStatus, JoiningType, MaxDomainLength, MaxLabelLength
export idnaUnicodeVersion