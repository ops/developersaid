# Developers' Aid for VIC-20

* Hacked together by ops in 2019 *

Developers' Aid is a cartridge for VIC-20 developers to help testing and debugging on real VIC-20 HW.

It is based on

- [Programmer's Aid](http://sleepingelephant.com/denial/wiki/index.php?title=VIC-1212_Programmers_Aid_Cartridge) cartridge
- [Over5](http://www.kahlin.net/daniel/over5/) transferring program by Daniel Kahlin
- C'mon Machine Code Monitor by Aleksi Eeben

# Documentation

[Manual](http://www.zimmers.net/anonftp/pub/cbm/vic20/manuals/VIC_1212_Programmers_Aid.pdf) for the original Programmer's Aid

[Manual](http://www.zimmers.net/anonftp/pub/cbm/vic20/programming/cmon.txt) for C'mon

Over5 [documentation](https://github.com/ops/over5/tree/master/doc)

Additional commands:

| Command | Description |
| --- | --- |
| OLD | Recover a BASIC program |
| CMON | Start Machine Code Monitor |
| O5RCV | Receive a file from host via serial line |
| O5SND | Send a file to host via serial line |
| DIRECTORY | Display disk direrecty to the screen |
| DISKCMD | Send disk command to the drive or read status|
| BASCAT | Display BASIC program directly to screen |

# Releases

## Release v0.1 (2019-07-xx)

Initial release.

Download [devaid-01.zip](releases/da_v1.0.zip).
