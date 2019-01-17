import unittest, ../src/devdep, parsetoml

suite "tools":
  test "tool checker - positive cases":
    let table = readTomlFile("./tests/success.toml")
    check toolChecker(table)

  test "tool checker - negative cases":
    let 
        table = readTomlFile("./tests/failure.toml")
        tools = table["tools"].getTable()

    for name, contents in tools.pairs:
        check:
            check(name, contents) == false
