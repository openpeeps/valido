# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import pkg/openparser/yaml
from std/strutils import strip

proc isYaml*(input: string): bool =
  ## Determine if given input is valid YAML.
  ## A plain scalar (e.g. `"hello"`) counts as valid YAML.
  if input.strip.len == 0: return false
  try:
    discard parseYAML(input)
    result = true
  except OpenParserYamlError: discard
  except: discard

proc isYamlStream*(input: string): bool =
  ## Determine if given input is a valid multi-document YAML stream.
  if input.strip.len == 0: return false
  try:
    discard parseYAMLStream(input)
    result = true
  except OpenParserYamlError: discard
  except: discard
