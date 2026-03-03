# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido

import pkg/blackpaper

proc isStrongPassword*(input: string, defaultEntropy = 3.8): bool =
  ## Checks given input and determine its strength based on the `passwordStrength`
  ## function provided by the `pkg/blackpaper`
  ## 
  ## Returns true if the password is classified as strong and meets the default entropy threshold.
  result = passwordStrength(input).strength == Strong and passwordStrength(input).score >= defaultEntropy