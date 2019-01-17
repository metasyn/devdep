# Package

version       = "0.1.0"
author        = "Alexander Johnson"
description   = "A tool for checking developers dependencies in a multi-developer project."
license       = "MIT"
srcDir        = "src"
bin           = @["devdep"]


# Dependencies
requires "nim >= 0.19.0"
requires "semver >= 1.1.0"
requires "parsetoml >= 0.4.0"
requires "docopt >= 0.6.8"