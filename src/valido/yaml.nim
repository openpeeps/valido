# Valido - A library of string validators and sanitizers
#
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/valido

import pkg/openparser/yaml
from std/strutils import strip, splitLines, startsWith

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
  ## Every document between `---` markers is validated on its own.
  if input.strip.len == 0: return false
  var documents: seq[string] = @[""]
  for line in input.splitLines:
    let marker = line.strip
    if marker == "---" or (marker.startsWith("--- ") and marker.len > 3):
      documents.add("")
    else:
      documents[^1].add(line)
      documents[^1].add("\n")
  var parsed = false
  for document in documents:
    if document.strip.len == 0: continue
    if not isYaml(document): return false
    parsed = true
  result = parsed
