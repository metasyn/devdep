# devdep

A CLI tool to check developer dependencies from a toml file.

## Motivation

When developing on a large project, developers often use their local environment to debug or develop. Usually there are a number of tools, internal and external, that they need to have as part of their toolchain. However, sometimes small version discrepancies in tool versioning can cause issues, from obvious security holes to subtle and hard to find bugs. Additionally, onboarding new members can be difficult, since some of those tools may not be documented in one place - and it may not be obvious which versions are compatible with project. Examples might include:

* container related tools (`docker`, `kubectl`)
* programming language version (`go version`)
* unix command line tools (`make`, `gpg`)

Rather, developer dependencies should not only be documented in one place, but should be documented in a machine readable way.

## devdep.toml

WIP: https://confluence.splunk.com/display/PROD/Versioned+Developer+Dependencies

## Usage

```
devdep - checks developer dependencies

Usage:
  devdep [-f <toml-config-file>]
  devdep (-h | --help)
  devdep (-v | --version)

Options:
  -f            Path to file to use.
  -h --help     Show this screen.
  -v --version  Show version.
```

## Developing

Make sure you have nim installed:

```bash
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```

Building:

```
nimble build
```

Testing:

```
nimble test
```

Running the tool:
```
nimble build
./devdep -h

# or

nimble install -y
devdep -h
```
