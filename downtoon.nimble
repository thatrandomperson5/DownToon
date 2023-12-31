# Package

version       = "0.1.0"
author        = "thatrandomperson5"
description   = "Download your favorite webcomics to read offline"
license       = "MIT"

when defined(windows):
  namedBin["src/downtoon"] = "downtoon.exe"
else:
  namedBin["src/downtoon"] = "downtoon"

# Dependencies

requires "nim >= 2.0.2"
requires "zippy"
requires "nimja"
requires "cligen"
requires "freeimage"
requires "nimquery"

when defined(gui): # Install GUI deps
  discard