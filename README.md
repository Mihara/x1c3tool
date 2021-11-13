# x1c3tool

This is a command line utility to save and restore the configuration of an [X1C3 APRS Tracker](https://www.venus-itech.com/product/x1c3-aprs-tracker/) device into a file.

The device is a rather neat Bluetooth SPP packet [TNC](https://en.wikipedia.org/wiki/Terminal_node_controller), comparable to [Mobilinkd TNC](http://www.mobilinkd.com/) -- while it's a bit cheaper, and not optimized for 9600 baud packet, it has its own GPS inside, and is capable of APRS beaconing and digipeating by itself when nothing is connected to it, making it an attractive competitor when you can get it to work.

However, the documentation is horrid and scarce. The stock software works only on Windows, due to being written in Visual Basic of all things.

Unfortunately, it is beyond me to rewrite the whole thing at the moment, *(I did write an [X1C3 manual](manual/manual.md), but that's the limit of what I can spare the time for at the moment)* so I did the next best thing: An utility to save and load the device's configuration, so that I can swap different profiles in the field without access to a Windows machine.

## Installation

Just get the executable suitable for your system from the Releases page and put it somewhere in your PATH. You're done.

Or you could compile from source yourself, see below.

## Usage

Really rather obvious. Attach the device by USB and invoke the magic words with the right serial port device:

```
x1c3tool /dev/ttyUSB0 --download my_home_config
x1c3tool /dev/ttyUSB0 --upload my_portable_config
```

Or on Windows:

```
x1c3tool.exe COM1 --download my_home_config
x1c3tool.exe COM1 --upload my_portable_config
```

Some programs have a different opinion about this word usage, hence the clarification: Uploading, here, means 'to device from file,' downloading means 'from device to file.'

## Technical details

X1C3 presents a serial port on the USB interface, and responds to a few scantily documented `AT+` commands.

Further description is [the subject of a user manual](manual/manual.md), but I've got to share my pain: While the extant documentation implies that you are supposed to set options with those `AT+` commands, hardly any of the ones it lists work, and the stock software does something completely different.

Beyond the commands that produce an immediate action, it invokes only two commands -- one which dumps the EEPROM of the device as bytes into the serial port, and one which reads this EEPROM from the port.

The stock software then works with the buffer itself, stuffing it out into the form that lets you edit it. The software -- and the layout of the EEPROM -- is identical for multiple very different devices by the same manufacturer *(notably, X1C5)* and half the toggles don't even do anything because a given device might not have these features at all. Just in case, my program specifically avoids messing with devices I do not actually own, because I can't test against them.

Naturally, this makes writing a program that flips a specific toggle in the stock software tricky. On the other hand, quickly switching between multiple "profiles" is easy, and this is what this program does.

## Compilation

`x1c3tool` is written in [Nim](https://nim-lang.org/). You shouldn't need anything else to compile it, though cross-platform building and producing static binaries is a different matter -- see comments in [x1c3tool.nimble](x1c3tool.nimble) for details.

It builds for all flavors of Linux, including Raspbian, as well as Windows command line. There is currently no OSX build and I don't know how to do one properly without building on OSX itself, though there's no reason it shouldn't be possible.

A simple `nimble build` will build an executable for your system, though it will not be the smallest possible, nor the most portable. To produce portable executables for all platforms, use `nimble release`. This is only designed to work on Ubuntu at the moment, if you feel up to helping, pull requests are welcome.

Released binaries are statically compiled and suitable for any Linux on the same CPU. Care was taken to produce small standalone executables with no dependencies.

## License

This program is licensed under the term of [MIT license](LICENSE).
