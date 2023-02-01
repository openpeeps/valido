# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

proc checkLuhn(cc: string): bool =
  # Luhn's algorithm. Originally from Rosetta Code
  # https://rosettacode.org/wiki/Luhn_test_of_credit_card_numbers
  const m = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]
  var
    t = 0
    odd = true
  for i in countdown(cc.high, 0):
    let digit = ord(cc[i]) - ord('0')
    t += (if odd: digit else: m[digit])
    odd = not odd
  result = t mod 10 == 0

proc isCard*(input: string): bool =
  checkLuhn(input)

when defined vCardExtras:
  ## Optionally, you can pass `-d:vCardExtras` compile flag.
  ## This will allow you to find bank information such as
  ## bank name, url and phone number,
  import ./country

  type
    CardType* = enum
      UnknownCardType
      DebitCard
      CreditCard

    CardCategory* = enum
      UnknownCardCategory
      BusinessCard
      StandardCard

    BankDetails* = tuple[
      bin: int,
      name: string,
      country: Country,
      phone, url: string,
      latitude, longitude: float
    ]

    CardBrand* = enum
      UnknownCardBrand
      AmericanExpress
      ChinaUnionPay
      Discover
      DinnersClub
      Enroute
      JCB
      MasterCard
      Maestro
      PrivateLabel
      Visa

    Card* = ref object
      brand: CardBrand
      cardType: CardType
      cardCategory: CardCategory
      bank: BankDetails

  proc isDebitCard*(input: string): bool =
    ## Validates given input and determine if the card
    ## type is Debit card

  proc isValid*(input: string): bool =
    ## Validates given input and determine if 
    ## is a valid card number.

  proc isVisa*(input: string): bool =
    ## 499999
    discard

  proc isMasterCard*(input: string): bool =
    # 510000 - 559999
    discard

  proc isMaestro*(input: string): bool =
    ## 500000 - 509999
    ## 560000 - 623999
    ## 627000 - 628199


  proc isAmericanExpress(input: string): bool =
    discard

  proc isChinaUnionPay*(input: string): bool =
    ## 624000 - 626999
    ## 628200 - 



