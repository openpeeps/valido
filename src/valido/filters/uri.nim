# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

from std/strutils import parseEnum

type
  SchemeURI* = enum
    ## IANA RFC-7595 Uniform Resource Identifiers
    ## https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
    Invalid
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
converter toSchemeURI(i: string): SchemeURI =
  try:
    result = parseEnum[SchemeURI](i)
  except ValueError:
    result = SchemeURI.Invalid

proc getScheme*(input: string) =
  ## Determine URI scheme from given input based on SchemeURI enumeration.
  echo toSchemeURI(input)