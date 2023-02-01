# Valido - A library of string validators and sanitizers
# 
# (c) 2023 George Lemon | MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/valido
import std/net
from strutils import split

proc checkIP(input: string, expect: IpAddressFamily): bool =
  try:
    let ipAddress = parseIpAddress(input)
    result = ipAddress.family == expect
  except ValueError:
    discard

proc checkIpGet(input: string, expect: IpAddressFamily): tuple[status: bool, ip: string] = 
  try:
    let ipAddr = parseIpAddress(input)
    result.status = ipAddr.family == expect
    case ipAddr.family:
      of IPv4:
        result.ip = $ipAddr
      of IPv6:
        result.ip = $ipAddr
  except ValueError: discard

proc checkIsReachable(ip: string, port: Port, timeout: int): bool =
  ## dummy stuff, this should implement a ping pong like using ICMP protocol
  let socket = newSocket()
  defer: socket.close()
  try:
    socket.connect(ip, port, timeout)
    result = true
  except OSError, TimeoutError: discard

proc isIP4*(input: string, allowLoopback = false): bool =
  ## Check if given input is a valid IPv4. Optionally,
  ## you can enable `allowLoopback` to include localhost addresses
  result = input.checkIP(IPv4)
  if result and not allowLoopback:
    if input.split(".")[0] == "127":
      result = false

proc isIP4Reachable*(input: string, port: Port = Port(80), timeout = 5000): bool =
  ## Checks if given input is a valid IPv4
  ## and try to determine if host is reachable.
  let i = input.checkIpGet(IPv4)
  if i.status:
    result = checkIsReachable(i.ip, port, timeout)

proc isIP6*(input: string, allowLoopback = false): bool =
  ## Check if given input is a valid `IPv6`. Set `allowLoopback`
  ## to allow localhost addresses.
  result = input.checkIP(IPv6)

proc isIP6Reachable*(input: string, port: Port = Port(80), timeout = 5000): bool =
  ## Checks if given input is a valid IPv4,
  ## and try to determine if host is reachable.
  let i = input.checkIpGet(IPv6)
  if i.status:
    result = checkIsReachable(i.ip, port, timeout)

# TODO DNS Lookup using
# https://github.com/rockcavera/nim-ndns