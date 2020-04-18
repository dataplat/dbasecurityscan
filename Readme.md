# dbaSecurityScan

## Module Status

| Win + WinPS | Win + PS7 | Linux + PS7 |
|---|---|---|
| ![Windows + Ps7](https://github.com/sqlcollaborative/dbasecurityscan/workflows/CI/badge.svg) | ![WindowsPS](https://github.com/sqlcollaborative/dbasecurityscan/workflows/WindowsPS/badge.svg) | ![LinuxPS](https://github.com/sqlcollaborative/dbasecurityscan/workflows/LinuxPS/badge.svg)

## Introduction

dbaSecurityScan is a PowerShell module designed to allow you to source control and test you database's security model

## Platform

We aim to be cross platform, PowerShell Core and PowerShell Windows friendly, and support SQL Server 2005+.

## Status

At the moment this module should be considered in alpha development, things are likely to change rapidly. While trying to avoid any breaking changes we can't guarantee they won't creep in over time

## Stuff that works 18/04/2020
Can create and test configs for Object, Schema, Role and User based security
Can fix Schema and User permission errors



## Dev Guidelines

- Module should support xplat, PS Core and Windows PowerShell
- Other than generic Sql Scripts, and other SQL Server data should be fetched using dbatools
  - So if extra data is needed, please add functionality to dbatools or tag the query as needing work
- Test for presence and absence, don't assume one means both
- Tests are good, any new commands show have tests.
-

## Examples
(consider some of this as aspirational rather than current reality)

To create a new config document:

`New-DssConfig -SqlInstance instance1 -Database test1 -ConfigPath ~/dbProject/security.json`

To test an new database against an existng document:

`Invoke-DssConfig -SqlInstance instance2 -Database AnotherDb -ConfigPath ~/dbProject/security.json`

Skip a step, and just pipe the config (coming soon)
`New-DssConfig -SqlInstance instance1 -Database test1 | Invoke-DssConfig -SqlServer instance2 -Database AnotherDb`

How about pulling the database back into line? You generated db1.json some time ago, and want to see if there's been any database drift

```
#Rehydrate the config object
$config = ConvertFrom-Json (Get-Content ./db1.json -raw)

#See if there's anything broken
$results = Invoke-DssTest -SqlInstance Instance1 -config $config

# Assume you've a sad face as lots of red failed tests have popped up :(
# Let's review what's going to happen first
$fixOutput = Reset-DssSecurity -SqlInstance Instance1 -TestResult $results -OutputOnly

# $fixOuput now contains all the actions that will be undertaken. Once you've happy, let's go ahead and apply those by removing the OutputOnly switch:
$fixOutput = Reset-DssSecurity -SqlInstance Instance1 -TestResult $results

# And you're back to baseline! You're a DBA so paranoia is a job description, so confirm:
$results = Invoke-DssTest -SqlInstance Instance1 -config $config

# No Red, happy faces all around
```

## ToDo

- Expand items included in config
- Expand public functions
- Improve build testing
- Add direct testing on top of meta data testing
- Command to add/remove permissions from configs
- Some form of graphical representation of the security model (Graph/PowerBI?)
- Documentation
- Write a proper developer wiki
