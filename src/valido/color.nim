import std/colors

proc isColor*(input: string): bool =
  return colors.isColor(input)