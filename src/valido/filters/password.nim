# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import std/[strutils, unicode]

type
    PasswordMessage* = enum
      passMinChars
      passUTF8Disallowed
      passConsecutiveChars
      passMinLowers
      passMinUppers
      passNoSpecials
      passOK

    PasswordStatus* = tuple[
      status: bool,
      msg: PasswordMessage
    ]
    PasswordRequirements* = tuple[
      minChars: int,
      incLowers, incUppers, incSpecials: bool,
      noRepeat, incUTF8: bool
    ]

let Specials = {'~', '!', '@', '#', '$', '%',
                '^', '&', '*', '(', ')', '-', '_',
                '+', '=', '`', ',', '.', '|',
                '/', '\'', '"', '\\', '?', '<', '>',
                '{', '}', '[', ']', ':', ';'}

template stop(msg: PasswordMessage): untyped =
  return (false, msg)

template ok(): untyped =
  return (true, passOK)

proc isPassword*(input: string, req: PasswordRequirements = (8, true, true, true, true, false)): PasswordStatus =
  ## Checks password strength. Use `PasswordRequirements` to adjust the filter.
  if input.len < req.minChars:
    stop passMinChars
  var i = 0
  var countUppers, countLowers, countSpecials, countRepeats: int
  if not req.incUTF8:
    while i <= input.high:
      if input[i] in Specials:
        inc countSpecials
      elif not input[i].isAlphaNumeric:
        stop passUTF8Disallowed
      elif input[i].isLowerAscii:
        inc countLowers
      elif input[i].isUpperAscii:
        inc countUppers
      try:
        if input[i] == input[i + 1]: inc countRepeats
      except IndexError: discard
      inc i
    if req.incUppers and countUppers == 0:     stop passMinUppers
    if req.incLowers and countLowers == 0:     stop passMinLowers
    if req.incSpecials and countSpecials == 0: stop passNoSpecials
    if req.noRepeat and countRepeats != 0:     stop passConsecutiveChars
    ok()
