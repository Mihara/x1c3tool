
import commandant
import serial
import streams
import strutils
import strscans
import json
import base64

const CRLF = "\x0d\x0a"
const EEPROM_SIZE = 512

proc helpMessage(): string =
  result = """
  x1c3tool -- an utility to save and load configuration from a 51Track X1C3 APRS Tracker.

  Usage:

    x1c3tool <serial port> --download <filename>
    x1c3tool <serial port> --upload <filename>

  Uploading means 'to device from file,' downloading means 'from device to file.'

  """

commandline:
  argument(portName, string)
  option(uploadFrom, string, "upload", "u")
  option(downloadTo, string, "download", "d")
  exitoption("help", "h", helpMessage())
  errormsg("--help for help.")

var
  port: SerialStream

try:
  port = newSerialStream(
    portName,
    int32(9600),
    Parity.None, 8, StopBits.One,
    readTimeout = 1000
  )
  echo("Working with ", portName)
except InvalidSerialPortError:
  quit("Could not open serial port " & portName, QuitFailure)

# Flush the port first.
try:
  discard port.readAll()
except TimeoutError:
  discard

# Get the firmware version number.
port.write("AT+VER=?" & CRLF)

# Expected version string is like:
# Ver: X1C3_2020_20201113 BH4TDV | ID: F628C58709A21E | V: 4.6 V|  25.8 C| 996.3 hpa
# It was reported that an older version writes the version number somewhat differently:
# Ver: 51X1C3_20180927A BH4TDV | CPU ID: F628465A00179D | Voltage: 4.6 V|

let
  response = port.readAll()

var
  version: string
  configBuffer: string

doAssert(
  scanf(response, " Ver: $* BH4TDV ", version),
  "This device doesn't look like a X1C3."
)

doAssert(version.startswith("X1C3") or version.startswith("51X1C3"), "This device is definitely not an X1C3.")

echo("X1C3 firmware version: ", version)

if len(downloadTo) != 0:

  echo("Downloading configuration to ", downloadTo)

  port.setTimeouts(5000, 5000)
  port.write("AT+SET=READ" & CRLF)
  configBuffer = port.readStr(5)
  doAssert(
    configBuffer == "HELLO",
    "Did not receive configuration dump header.")

  # This also skips this marker, the remainder should be exactly 512 bytes long...
  configBuffer = port.readStr(EEPROM_SIZE)
  doAssert(
    len(configBuffer) == EEPROM_SIZE,
    "Something went wrong, not enough bytes received.")

  let cfg = %* {"firmware": version, "data": base64.encode(configBuffer)}
  writeFile(downloadTo, $cfg)

elif len(uploadFrom) != 0:

  echo("Uploading configuration from ", uploadFrom)

  let cfg = parseJson(readFile(uploadFrom))
  doAssert(
    cfg["firmware"].kind == JString and cfg["data"].kind == JString,
    "File format doesn't seem correct.")
  doAssert(
    cfg["firmware"].getStr() == version,
    "Firmware version of the stored configuration doesn't match the device.")

  let configBuffer = base64.decode(cfg["data"].getStr())
  doAssert(
    len(configBuffer) == EEPROM_SIZE,
    "Size of the stored EEPROM data is wrong."
  )

  port.write("AT+SET=WRITE")
  port.write(configBuffer)

else:
  echo("Nothing to upload or download.")

echo("Done.")
port.close()
