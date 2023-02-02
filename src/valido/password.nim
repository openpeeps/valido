# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import pkg/zxcvbn

proc isStrongPassword*(input: string, defaultEntropy = 50.00): bool =
  ## Checks given input and determine its strength
  result = passwordEntropy(input) > defaultEntropy