# dbaSecurityScan

[![Build status](https://ci.appveyor.com/api/projects/status/74nvvgd7yqxb7l70?svg=true)](https://ci.appveyor.com/project/Stuart-Moore/dbasecurityscan)

## Introduction

dbaSecurityScan is a PowerShell module designed to allow you to source control and test you database's security model

## Status

At the moment this module should be considered in alpha development, things are likely to change rapidly. While trying to avoid any breaking changes we can't guarantee they won't creep in over time

## Dev Guidelines

- Module should support xplat, PS Core and Windows PowerShell
- Other than generic Sql Scripts, and other SQL Server data should be fetched using dbatools
    - So if extra data is needed, please add functionality to dbatools
- Test for presence and absence, don't assume 1 means the other

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
