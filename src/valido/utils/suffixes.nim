# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeeps/valido

## Curated list of multi-label public suffixes.
##
## `GetTLDs` holds the IANA root zone, which is a single label: `com`, `de`,
## `xn--p1ai`. Plenty of country code TLDs delegate to second level domains
## though, so `example.co.uk` is a three label name whose effective TLD is the
## two label suffix `co.uk`.
##
## This list holds the common ones. It is deliberately not the full Public
## Suffix List, which is far too large to embed. Pass ``checkTld = false`` when
## you need to accept a country code suffix that is missing here.
##
## Keep the list sorted, `isDomainName` binary searches it.

const GetPublicSuffixes* = [
    "ac.at",
    "ac.be",
    "ac.cn",
    "ac.il",
    "ac.nz",
    "ac.uk",
    "ad.at",
    "co.at",
    "co.il",
    "co.in",
    "co.it",
    "co.jp",
    "co.kr",
    "co.ma",
    "co.nz",
    "co.th",
    "co.uk",
    "co.za",
    "com.ar",
    "com.au",
    "com.br",
    "com.cn",
    "com.co",
    "com.cy",
    "com.eg",
    "com.gr",
    "com.hk",
    "com.mx",
    "com.my",
    "com.ng",
    "com.pe",
    "com.ph",
    "com.pl",
    "com.pt",
    "com.sa",
    "com.sg",
    "com.tr",
    "com.tw",
    "com.ua",
    "com.uy",
    "com.ve",
    "com.vn",
    "edu.au",
    "edu.pl",
    "es.cat",
    "firm.in",
    "gen.in",
    "gov.au",
    "gov.br",
    "gov.in",
    "gov.pl",
    "gov.uk",
    "ind.in",
    "me.uk",
    "mil.uk",
    "net.au",
    "net.br",
    "net.cn",
    "net.in",
    "net.mx",
    "net.nz",
    "net.uk",
    "nic.in",
    "nom.br",
    "org.au",
    "org.br",
    "org.cn",
    "org.il",
    "org.in",
    "org.jp",
    "org.kr",
    "org.mx",
    "org.my",
    "org.ng",
    "org.pl",
    "org.tr",
    "org.tw",
    "org.ua",
    "org.uk",
    "org.ve",
    "priv.in",
    "web.app",
]