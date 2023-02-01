from strutils import parseInt

proc checkPort(input: int, strict: bool): bool =
  if strict:
    return input >= 1024 and input <= 65535
  result = input >= 0 and input <= 65535 

proc isPort*(input: int, strict = false): bool =
  result = checkPort(input, strict)

proc isPort*(input: string, strict = false): bool =
  try:
    result = checkPort(parseInt(input), strict)
  except ValueError: discard