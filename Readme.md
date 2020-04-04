# dbaSecurityScan

![Windows CI](https://github.com/sqlcollaborative/dbasecurityscan/workflows/CI/badge.svg)

## Introduction

dbaSecurityScan is a PowerShell module designed to allow you to source control and test you database's security model

## Platform

We aim to be cross platform, PowerShell Core and PowerShell Windows friendly, and support SQL Server 2005+.

## Status

At the moment this module should be considered in alpha development, things are likely to change rapidly. While trying to avoid any breaking changes we can't guarantee they won't creep in over time

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
`New-DssConfig -SqlServer instance1 -Database test1 -ConfigPath ~/dbProject/security.json`

To test an new database againt an exisitng document:
`Invoke-DssConfig -SqlServer instance2 -Database AnotherDb -ConfigPath ~/dbProject/security.json`

Skip a step, and just pipe the config
`New-DssConfig -SqlServer instance1 -Database test1 | Invoke-DssConfig -SqlServer instance2 -Database AnotherDb` 

## ToDo

- Expand items included in config
- Expand public functions
- Improve build testing
- Add direct testing on top of meta data testing
- Command to add/remove permissions from configs
- Some form of graphical representation of the security model (Graph/PowerBI?)
- Documentation
- Write a proper developer wiki

