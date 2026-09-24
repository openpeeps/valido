import times

proc isDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as a date
  try:
    discard parse(input, format)
    result = true
  except TimeParseError, TimeFormatParseError:
    discard

proc isPastDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as past date
  try:
    let d = parse(input, format, utc())
    if now() > d:
      result = true
  except TimeParseError, TimeFormatParseError:
    discard

proc isFutureDate*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as future date
  try:
    let d = parse(input, format, utc())
    if d > now():
      result = true
  except TimeParseError, TimeFormatParseError:
    discard

proc isToday*(input: string, format = "yyyy-MM-dd"): bool =
  ## Checks if given input can be parsed as today's date
  try:
    let d = parse(input, format, utc())
    let n = now().utc()
    result = d.year == n.year and d.month == n.month and
             d.monthday == n.monthday
  except TimeParseError, TimeFormatParseError:
    discard