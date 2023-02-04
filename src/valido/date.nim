import times

proc isDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as a date
  try:
    discard parse(input, format)
    result = true
  except TimeParseError, TimeFormatParseError, Defect:
    discard

proc isPastDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as past date
  try:
    let d = parse(input, format, utc())
    if now() > d:
      result = true
  except TimeParseError, TimeFormatParseError, Defect:
    discard

proc isFutureDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as future date
  try:
    let d = parse(input, format, utc())
    if d > now():
      result = true
  except TimeParseError, TimeFormatParseError, Defect:
    discard

proc isToday*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input an be parsed as a date in present
  try:
    let d = parse(input, format, utc())
    if d == now():
      result = true
  except TimeParseError, TimeFormatParseError, Defect:
    discard