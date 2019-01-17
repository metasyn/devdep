import re
import terminal
from os import fileExists
from osproc import execProcess
from strformat import fmt
from strutils import align, strip

# Third party
import parsetoml
import semver

const defaultFileName = "devdep.toml"

type 
  TomlException* = object of Exception
  ParsingException* = object of Exception
  ExecutionException* = object of Exception

proc colored(color: ForegroundColor, msg, prefix: string) =
  styledWriteLine(stdout, color, align(prefix, 10), resetStyle, msg)

proc info(msg, prefix = "Info: ") =
  colored(fgCyan, msg, prefix)

proc error(msg, prefix = "Error: ") =
  colored(fgRed, msg, prefix)

proc success(msg, prefix = "Success: ") =
  colored(fgGreen, msg, prefix)

proc readTomlFile*(filename: string): TomlTableRef =
  ## Read a toml file from a particular file path
  if not filename.fileExists():
    let msg = fmt"Could not find {filename}."
    raise newException(TomlException, msg)
  result = filename.parseFile().getTable()
  
proc extractVersion(s: string, regex: Regex): string =
  ## Extract the version from the output of a command using a regex
  var matches: array[1, string]
  if re.match(s, regex, matches):
    result = matches[0]
  else:
    let msg = "Could not extract version"
    raise newException(ExecutionException, msg)

proc parseConstraint(s: string): tuple[constraint, version: string] =
  ## Parse the constraint from the string
  ## Must be one of:
  ## = : equal to
  ## != : not equal to
  ## >= : greater than or equal to
  ## > : greater than 
  ## <= : less than or equal to
  ## < : less than 
  ## ^ : major version compliant
  ## ~ : minor version compliant
  var matches: array[2, string]
  let regex = re"(=|!=|>=|<=|>|<|\^|~)(.+)"
  if re.match(s, regex, matches):
    if len(matches) != 2:
      let validConstraints = "=, !=, >, >=, <, <=, ^, ~"
      let msg  = fmt"""Could not parse constraint from "{s}": - must be one of {validConstraints}"""
      raise newException(ParsingException, msg)

    result = (matches[0], matches[1])

proc checkVersion(versionConstraint, versionExtracted: string): bool =
  let 
    (constraint, version) = parseConstraint(versionConstraint)
    # Parse semantic versions
    semVerConstraint = v(version)
    semVerExtracted = v(versionExtracted)

  case constraint
  of "=":
    return semVerExtracted == semVerConstraint
  of "!=":
    return semVerExtracted != semVerConstraint
  of ">":
    return semVerExtracted > semVerConstraint
  of ">=":
    return semVerExtracted >= semVerConstraint
  of "<":
    return semVerExtracted < semVerConstraint
  of "<=":
    return semVerExtracted <= semVerConstraint
  of "^":
    return (
      semVerExtracted.major == semVerConstraint.major and 
      semVerExtracted.minor >= semVerConstraint.minor )
  of "~":
    return (
      semVerExtracted.major == semVerConstraint.major and 
      semVerExtracted.minor == semVerConstraint.minor and
      semVerExtracted.patch >= semVerConstraint.patch )

proc check*(name: string, tool: TomlValueRef): bool =
  ## Check that a particular tool meets the version constraint.
  let command = tool["command"].getStr()
  var output: string
  try:
    output = execProcess(command)
  except:
    let 
      msg = get_currentExceptionMsg()
      help = fmt"Error encoutner while executing {command}: {msg}"
    raise newException(ExecutionException, help)

  var matches: array[1, string]
  if re.match(output, re".*command not found", matches):
    let url = tool["url"].getStr()
    error(output.strip)
    error(fmt"See {url} to obtain.", prefix="")
    return false

  let
    versionRegex = re.re(tool["version-regex"].getStr())
    versionExtracted = output.extractVersion(versionRegex)
    versionConstraint = tool["version-required"].getStr()

  let valid = checkVersion(versionConstraint, versionExtracted)

  if valid:
    success(fmt"{name} is valid")
    return true
  if not valid:
    error(fmt"{name} is invalid. Have {versionExtracted} but need {versionConstraint}")
    return false

proc toolChecker*(table: TomlTableRef): bool =
  info("tools", prefix="Checking: ")
  if not table.contains("tools"):
    echo fmt"No tools to check..."

  let tools = table["tools"].getTable()
  let numTools = len(tools)
  var count: int
  var totalSuccess = true

  for name, contents in tools.pairs:
    count += 1
    try:
      let valid = check(name, contents)
      if not valid:
        totalSuccess = false
    except:
      let msg = getCurrentExceptionMsg()
      error(fmt"""Failure when checking tool "{name}": {msg}""")
  
  return totalSuccess

when isMainModule:
  import docopt
  let doc = """
devdep - checks developer dependencies

Usage:
  devdep [-f <toml-config-file>]
  devdep (-h | --help)
  devdep (-v | --version)

Options:
  -f            Path to file to use.
  -h --help     Show this screen.
  -v --version  Show version.
  
"""
  let args =  docopt(doc, version = "devdep 0.1.0")

  var fileName: string

  if args["-f"]:
    fileName = $args["<toml-config-file>"]
  else:
    fileName = defaultFileName

  let 
    tomlTable = readTomlFile(fileName)
    toolSuccess = toolChecker(tomlTable)
  
  if not toolSuccess:
    quit(1)
