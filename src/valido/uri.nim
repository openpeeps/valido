# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import std/strutils
import std/options
import pkg/openparser/path
import ./domain
import ./email
import ./ip
import ./port

type
  SchemeURI* = enum
    ## IANA RFC-7595 Uniform Resource Identifiers
    ## https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
    Invalid
    Http = "http"
      ## Hypertext Transfer Protocol
      ## http://<host>[:<port>]/<url-path>
    Https = "https"
      ## Hypertext Transfer Protocol over TLS
      ## https://<host>[:<port>]/<url-path>
    Android = "android"
      ## Identifies an Android application
      ## android://<application-id>
    Bitcoin = "bitcoin"
      ## Send money to a Bitcoin address
      ## bitcoin:<address>[?[amount=<size>][&][label=<label>][&][message=<message>]]

    BitcoinCash = "bitcoincash"
      ## Send money to a Bitcoin Cash address
      ## bitcoincash:<address>[?[amount=<size>][&][label=<label>][&][message=<message>]]

    Chrome = "chrome"
      ## chrome://<package>/<section>/<path> (Where <section> is either "content", "skin" or "locale")
      ## https://www.iana.org/assignments/uri-schemes/prov/chrome

    ChromeExtension = "chrome-extension"
      ## chrome-extension://<extensionID>/<pageName>.html (Where <extensionID> is the
      ## ID given to the extension by "Chrome Web Store" and <pageName> is the location of an HTML page)
      ## Management of setting of extensions which have been installed.

    FaceTime = "facetime"
      ## facetime://<address>|<MSISDN>|<mobile number>
      ## example: facetime://+19995551234
    Feed = "feed"
      ## web irc6://<host>[:<port>]/[<channel>[?<password>]]feed subscription
      ## feed:<absolute_uri> or feed://<hierarchical part>
    Ftp = "ftp"
      ## ftp://[user[:password]@]host[:port]/url-path
    Git = "git"
      ## Provides a link to a GIT repository
      ## git://github.com/user/project-name.git
    Irc = "irc"
      ## Connecting to an Internet Relay Chat server to join a channel
      ## irc://<host>[:<port>]/[<channel>[?<password>]]
    Irc6 = "irc6"
      ## IPv6 equivalent of irc used by KVIrc
      ## irc6://<host>[:<port>]/[<channel>[?<password>]]
    Ircs = "ircs"
      ## Secure equivalent of irc
      ## ircs://<host>[:<port>]/[<channel>[?<password>]]
    Ldaps = "ldaps"
      ## Secure equivalent of ldap
      ## ldaps://[<host>[:<port>]][/<dn> [?[<attributes>][?[<scope>][?[<filter>][?<extensions>]]]]]
    MongoDB = "mongodb"
      ## mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?options]]
    Market = "market"
      ## Opens Google Play
      ## market://details?id=Package_name or market://search?q=Search_Query
      ## market://search?q=pub:Publisher_Name
    Message = "message"
      ## Direct link to specific email message
      ## message:<MESSAGE-ID>
      ## message://<MESSAGE-ID>
    Sftp = "sftp"
      ## SFTP file transfers (not be to confused with FTPS (FTP/SSL))
      ## sftp://[<user>[;fingerprint=<host-key fingerprint>]@]<host>[:<port>]/<path>/<file>
    Ssh = "ssh"
      ## SSH connections (like telnet:)
      ## ssh://[<user>[;fingerprint=<host-key fingerprint>]@]<host>[:<port>]
    Mailto = "mailto"
      ## Electronic mail address
      ## mailto:<address>

converter toSchemeURI*(i: string): SchemeURI =
  try:
    result = parseEnum[SchemeURI](i)
  except ValueError:
    result = SchemeURI.Invalid

proc getScheme*(input: string): SchemeURI =
  ## Determine URI scheme from given input based on SchemeURI enumeration.
  let s = input.strip()
  let colon = s.find(':')
  if colon <= 0: return SchemeURI.Invalid
  result = toSchemeURI(s[0 ..< colon].toLowerAscii())

# -- internal helpers --

proc splitScheme(s: string): tuple[ok: bool, scheme, rest: string] =
  let input = s.strip()
  let colon = input.find(':')
  if colon <= 0: return (false, "", "")
  let scheme = input[0 ..< colon].toLowerAscii()
  if scheme.len == 0 or scheme[0] notin {'a'..'z'}: return (false, "", "")
  for c in scheme:
    if c notin {'a'..'z', '0'..'9', '+', '-', '.'}: return (false, "", "")
  (true, scheme, input[colon + 1 .. ^1])

proc isLocalHostname(h: string): bool =
  if h.len == 0 or h.len > 253: return false
  if ' ' in h or '/' in h or '@' in h: return false
  if h[0] == '-' or h[0] == '.' or h[^1] == '-' or h[^1] == '.': return false
  for c in h:
    if c notin {'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_'}: return false
  true

proc isValidHost(h: string): bool =
  if h.len == 0: return false
  if isIP4(h, allowLoopback = true): return true
  if isIP6(h, allowLoopback = true): return true
  if '.' in h:
    if isDomain(h): return true
  result = isLocalHostname(h)

proc validPortStr(p: string): bool =
  if p.len == 0: return false
  try:
    let v = parseInt(p)
    result = v >= 0 and v <= 65535
  except ValueError: discard

proc stripSlashes(rest: string): string =
  if rest.startsWith("//"): rest[2 .. ^1] else: rest

proc splitAuthorityPath(s: string): tuple[authority, path: string] =
  let slash = s.find('/')
  if slash < 0: (s, "")
  else: (s[0 ..< slash], s[slash .. ^1])

proc checkAuthority(authority: string, allowUser = true): tuple[ok: bool, host: string] =
  ## Validate `[user[:password]@]host[:port]`, return host.
  var rest = authority
  if rest.len == 0: return (false, "")
  if allowUser:
    let at = rest.rfind('@')
    if at >= 0:
      let userInfo = rest[0 ..< at]
      rest = rest[at + 1 .. ^1]
      if userInfo.len == 0 or rest.len == 0: return (false, "")
  # IPv6 literal
  if rest.startsWith('['):
    let close = rest.find(']')
    if close < 0: return (false, "")
    let host = rest[1 ..< close]
    if not isIP6(host, allowLoopback = true): return (false, "")
    let after = rest[close + 1 .. ^1]
    if after.len > 0:
      if not after.startsWith(':'): return (false, "")
      if not validPortStr(after[1 .. ^1]): return (false, "")
    return (true, host)
  let colon = rest.rfind(':')
  var host = rest
  if colon >= 0:
    let maybePort = rest[colon + 1 .. ^1]
    if maybePort.len > 0 and validPortStr(maybePort):
      host = rest[0 ..< colon]
    elif ':' in rest and not ('.' in rest):
      return (false, "") # bare IPv6 without brackets
  if not isValidHost(host): return (false, "")
  (true, host)

proc pathKindOk(input: string, kind: PathKind): tuple[ok: bool, host: string] =
  try:
    let p = parsePath(input.strip())
    if p.kind != kind or p.isLocal: return (false, "")
    if not isValidHost(p.host): return (false, "")
    if p.port.isSome and not isPort(p.port.get()): return (false, "")
    (true, p.host)
  except OpenParserPathError: (false, "")
  except: (false, "")

# -- specific validators (generic isUri/isUrl defined at bottom) --

proc isWebUrl*(input: string): bool =
  ## `http(s)://[user[:pass]@]host[:port][/path][?query][#fragment]`.
  let s = input.strip()
  let (ok, scheme, _) = splitScheme(s)
  if not ok or scheme notin ["http", "https"]: return false
  let (_, host) = pathKindOk(s, pkWeb)
  result = host.len > 0

proc isFtpUri*(input: string): bool =
  ## `ftp://[user[:password]@]host[:port]/url-path`.
  let s = input.strip()
  let (ok, scheme, _) = splitScheme(s)
  if not ok or scheme != "ftp": return false
  let (pok, _) = pathKindOk(s, pkFTP)
  result = pok

proc isSftpUri*(input: string): bool =
  ## `sftp://[user[;fingerprint=..]@]host[:port]/path/file`.
  let s = input.strip()
  let (ok, scheme, _) = splitScheme(s)
  if not ok or scheme != "sftp": return false
  let (pok, _) = pathKindOk(s, pkSFTP)
  result = pok

proc isSshUri*(input: string): bool =
  ## `ssh://[user[;fingerprint=..]@]host[:port]`.
  let s = input.strip()
  let (ok, scheme, _) = splitScheme(s)
  if not ok or scheme != "ssh": return false
  let (pok, _) = pathKindOk(s, pkSSH)
  result = pok

proc isGitUri*(input: string): bool =
  ## `git://host/user/repo.git`, `git+ssh://`, `git+https://`, `git+http://`,
  ## or a plain `http(s)://host/user/repo.git` clone URL.
  let s = input.strip()
  let (ok, scheme, _) = splitScheme(s)
  if not ok: return false
  if scheme in ["http", "https"]:
    let (pok, _) = pathKindOk(s, pkWeb)
    if not pok: return false
    try:
      let p = parsePath(s)
      return p.pathSegments.len > 0 and p.path.endsWith(".git")
    except: discard
    return false
  if scheme notin ["git", "git+ssh", "git+https", "git+http"]: return false
  let (pok, _) = pathKindOk(s, pkGit)
  if not pok: return false
  # common convention: path ends in .git (allow bare path too if non-empty)
  try:
    let p = parsePath(s)
    result = p.path.len == 0 or p.path.endsWith(".git") or p.pathSegments.len > 0
  except: discard

proc isMailto*(input: string): bool =
  ## `mailto:addr@host`.
  let s = input.strip()
  let (ok, scheme, rest) = splitScheme(s)
  if not ok or scheme != "mailto": return false
  result = isEmail(rest.strip())

proc isFileUri*(input: string): bool =
  ## `file://<host>/<path>` where the host is empty or `localhost`.
  ## Windows drive paths are also accepted, e.g. `file:///C:/path/file.txt`.
  let s = input.strip()
  let (ok, scheme, rest) = splitScheme(s)
  if not ok or scheme != "file": return false
  if rest.len == 0: return false
  if not rest.startsWith("//"): return false
  var afterSlashes = rest[2 .. ^1]
  if afterSlashes.len == 0: return false
  let slash = afterSlashes.find('/')
  if slash < 0:
    # file://host with no path: only allowed for localhost
    return afterSlashes.toLowerAscii() == "localhost"
  let host = afterSlashes[0 ..< slash]
  if host.len > 0 and host.toLowerAscii() != "localhost": return false
  let pathPart = afterSlashes[slash .. ^1]
  if pathPart.len <= 1: return false
  if ' ' in pathPart or '\0' in pathPart: return false
  result = true

proc isAndroidUri*(input: string): bool =
  ## `android://<application-id>`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "android": return false
  let app = stripSlashes(rest.strip())
  if app.len == 0 or ' ' in app or '/' in app: return false
  for c in app:
    if c notin {'a'..'z', 'A'..'Z', '0'..'9', '_', '.'}: return false
  true

proc validBitcoinQuery(q: string): bool =
  if q.len == 0: return true
  for pair in q.split('&'):
    let eq = pair.find('=')
    if eq <= 0: return false
    let k = pair[0 ..< eq].toLowerAscii()
    let v = pair[eq + 1 .. ^1]
    if k notin ["amount", "label", "message"] or v.len == 0: return false
    if k == "amount":
      var f = 0.0
      try:
        if v.len == 0: return false
        discard parseFloat(v)
      except ValueError: return false
      discard f
  true

proc checkBitcoinAddr(scheme, input: string): bool =
  let (ok, found, rest) = splitScheme(input)
  if not ok or found != scheme: return false
  var addrPart = rest.strip()
  if addrPart.startsWith("//"): addrPart = addrPart[2 .. ^1]
  if addrPart.len == 0: return false
  var address = addrPart
  var query = ""
  let q = addrPart.find('?')
  if q >= 0:
    address = addrPart[0 ..< q]
    query = addrPart[q + 1 .. ^1]
  if address.len < 26 or address.len > 90: return false
  for c in address:
    if c notin {'a'..'z', 'A'..'Z', '0'..'9'}: return false
  validBitcoinQuery(query)

proc isBitcoinUri*(input: string): bool =
  ## `bitcoin:<address>[?amount=..&label=..&message=..]`.
  checkBitcoinAddr("bitcoin", input)

proc isBitcoinCashUri*(input: string): bool =
  ## `bitcoincash:<address>[?amount=..&label=..&message=..]`.
  checkBitcoinAddr("bitcoincash", input)

proc isChromeUri*(input: string): bool =
  ## `chrome://<package>/<section>/<path>` with section in content/skin/locale.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "chrome": return false
  let noSlashes = stripSlashes(rest.strip())
  let parts = noSlashes.split('/')
  if parts.len < 3 or parts[0].len == 0: return false
  if parts[1] notin ["content", "skin", "locale"]: return false
  if parts[2].len == 0: return false
  true

proc isChromeExtensionUri*(input: string): bool =
  ## `chrome-extension://<extensionID>/<page>.html`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "chrome-extension": return false
  let noSlashes = stripSlashes(rest.strip())
  let slash = noSlashes.find('/')
  if slash <= 0: return false
  let extId = noSlashes[0 ..< slash]
  let page = noSlashes[slash + 1 .. ^1]
  if extId.len != 32 or page.len == 0: return false
  for c in extId:
    if c notin {'a'..'z'}: return false
  page.toLowerAscii().endsWith(".html")

proc isFaceTimeUri*(input: string): bool =
  ## `facetime://<address|MSISDN|mobile>`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "facetime": return false
  let target = stripSlashes(rest.strip())
  if target.len == 0: return false
  if '@' in target: return isEmail(target)
  var digits = target
  if digits.startsWith('+'): digits = digits[1 .. ^1]
  if digits.len < 7 or digits.len > 15: return false
  for c in digits:
    if c notin {'0'..'9'}: return false
  true

proc isFeedUri*(input: string): bool =
  ## `feed:<absolute_uri>` or `feed://<hierarchical part>`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "feed": return false
  let inner = rest.strip()
  if inner.len == 0: return false
  if inner.startsWith("//"):
    let host = stripSlashes(inner).split('/')[0].split('?')[0].split('#')[0]
    return isValidHost(host)
  result = isWebUrl(inner)

proc checkIrc(scheme, input: string): bool =
  let (ok, found, rest) = splitScheme(input)
  if not ok or found != scheme: return false
  let noSlashes = stripSlashes(rest.strip())
  if noSlashes.len == 0: return false
  let (authority, path) = splitAuthorityPath(noSlashes)
  let (aok, _) = checkAuthority(authority)
  if not aok: return false
  if path.len == 0: return true
  var channel = path[1 .. ^1]
  let q = channel.find('?')
  if q >= 0: channel = channel[0 ..< q]
  channel.len == 0 or channel.startsWith('#') or channel.len > 0

proc isIrcUri*(input: string): bool =
  ## `irc://<host>[:<port>]/[<channel>[?<password>]]`.
  checkIrc("irc", input)

proc isIrc6Uri*(input: string): bool =
  checkIrc("irc6", input)

proc isIrcsUri*(input: string): bool =
  checkIrc("ircs", input)

proc isLdapsUri*(input: string): bool =
  ## `ldaps://[host[:port]][/dn[?attrs[?scope[?filter[?ext]]]]]`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "ldaps": return false
  let noSlashes = stripSlashes(rest.strip())
  if noSlashes.len == 0: return false
  let (authority, _) = splitAuthorityPath(noSlashes)
  let (aok, _) = checkAuthority(authority)
  aok

proc isMongoDbUri*(input: string): bool =
  ## `mongodb://[user:pass@]host1[:port1][,hostN[:portN]][/db][?options]`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "mongodb": return false
  var noSlashes = stripSlashes(rest.strip())
  if noSlashes.len == 0: return false
  # strip /database and ?options
  let slash = noSlashes.find('/')
  var hostsPart = noSlashes
  if slash >= 0: hostsPart = noSlashes[0 ..< slash]
  let at = hostsPart.rfind('@')
  if at >= 0: hostsPart = hostsPart[at + 1 .. ^1]
  if hostsPart.len == 0: return false
  for h in hostsPart.split(','):
    var host = h
    var port = ""
    let colon = h.rfind(':')
    if colon >= 0:
      host = h[0 ..< colon]
      port = h[colon + 1 .. ^1]
      if not validPortStr(port): return false
    if not isValidHost(host): return false
  true

proc isMarketUri*(input: string): bool =
  ## `market://details?id=..` or `market://search?q=..`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "market": return false
  let noSlashes = stripSlashes(rest.strip())
  let q = noSlashes.find('?')
  if q <= 0: return false
  let host = noSlashes[0 ..< q].toLowerAscii()
  let query = noSlashes[q + 1 .. ^1]
  if host notin ["details", "search"]: return false
  if query.len == 0: return false
  var hasKey = false
  for pair in query.split('&'):
    let eq = pair.find('=')
    if eq <= 0 or pair[eq + 1 .. ^1].len == 0: return false
    let k = pair[0 ..< eq].toLowerAscii()
    if host == "details" and k == "id": hasKey = true
    if host == "search" and k == "q": hasKey = true
  hasKey

proc isMessageUri*(input: string): bool =
  ## `message:<MESSAGE-ID>` or `message://<MESSAGE-ID>`.
  let (ok, scheme, rest) = splitScheme(input)
  if not ok or scheme != "message": return false
  var idPart = rest.strip()
  if idPart.startsWith("//"): idPart = idPart[2 .. ^1]
  if idPart.len == 0 or ' ' in idPart: return false
  '@' in idPart

# -- generic validators --

proc isUri*(input: string): bool =
  ## Determine if given input is a URI: valid `scheme:` prefix plus
  ## per-scheme format validation (see `SchemeURI` `##` docs).
  ## Unknown schemes return false.
  let s = input.strip()
  if s.len == 0: return false
  let (ok, scheme, _) = splitScheme(s)
  if not ok: return false
  case scheme
  of "http", "https": result = isWebUrl(s)
  of "ftp": result = isFtpUri(s)
  of "sftp": result = isSftpUri(s)
  of "ssh": result = isSshUri(s)
  of "git", "git+ssh", "git+https", "git+http": result = isGitUri(s)
  of "mailto": result = isMailto(s)
  of "file": result = isFileUri(s)
  of "android": result = isAndroidUri(s)
  of "bitcoin": result = isBitcoinUri(s)
  of "bitcoincash": result = isBitcoinCashUri(s)
  of "chrome": result = isChromeUri(s)
  of "chrome-extension": result = isChromeExtensionUri(s)
  of "facetime": result = isFaceTimeUri(s)
  of "feed": result = isFeedUri(s)
  of "irc": result = isIrcUri(s)
  of "irc6": result = isIrc6Uri(s)
  of "ircs": result = isIrcsUri(s)
  of "ldaps": result = isLdapsUri(s)
  of "mongodb": result = isMongoDbUri(s)
  of "market": result = isMarketUri(s)
  of "message": result = isMessageUri(s)
  else: result = false

proc isUri*(input: string, scheme: SchemeURI): bool =
  ## Determine if given input is a URI of the expected scheme (format-validated).
  if scheme == SchemeURI.Invalid: return false
  let s = input.strip()
  let (ok, found, _) = splitScheme(s)
  if not ok or found != ($scheme).toLowerAscii(): return false
  result = isUri(s)

proc isUrl*(input: string): bool =
  ## Alias of isWebUrl.
  isWebUrl(input)
