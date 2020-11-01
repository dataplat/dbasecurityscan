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

Pester v4 is a hard requirement. It the module can't find it at load time it will throw an error. We will support Pester v5 at some point

## Stuff that works 01/11/2020
Can create and test configs for Object, Schema, Role and User based security
Can fix Schema, Object, Role and User permission errors
Policies added

## Tests vs Policies
We have 2 ways of tracking configuration:

- Policies; these are checks with a single answer (true, false, 2) evaluated once for the whole database. For example, 'No User Permissions allowed' is true or false
- Tests; these can have many answers per database. For example, 'Get all Role permissions for db1' could have many different return sets


## Dev Guidelines

- Module should support xplat, PS Core and Windows PowerShell
- Other than generic Sql Scripts, and other SQL Server data should be fetched using dbatools
  - So if extra data is needed, please add functionality to dbatools or tag the query as needing work
- Test for presence and absence, don't assume one means both
- Tests are good, any new commands should have tests.

## Examples

This example uses the roles database from the testing folder. This demo assumes you're running at the module root folder

```
--Setup a few environment variable
$sqlUser='sqluser'
$sqlPasswd= ConvertTo-SecureString 'P@ssw0rdl!ng' -AsPlainText -Force
$sqlCred=New-Object System.Management.Automation.PSCredential ($sqlUser, $sqlPasswd)
$sqlInstance='localhost:1433'
$appsplat=@{
  SqlInstance =$sqlInstance
  SqlCredential = $sqlCred
}

$srv = Connect-DbaInstance @appsplat
$c = Get-Content './Tests/scenarios/roles1/roles1.sql' -Raw
$srv.Databases['master'].ExecuteNonQuery($c)

--create a new config
$config = New-DssConfig @appsplat -Database roles1

--remove config file
Remove-Item ./dss.json -Force

--write out the config to a file
$config | ConvertTo-Json -Depth 5 | Out-File ./dss.json

--take a look at the config file in vs code
code ./dssNotts.json

--Add an extra permission to the role
Invoke-DbaQuery @appsplat -Database roles1 -Query "grant execute on sp_test to removerole"

--run a compare against the config.
$results = Invoke-DssTest @appsplat -Database roles1 -Config $config

--errors were returned so try a dryrun to see how they could be fixed
$dryRun = Reset-DssSecurity @appsplat -Database roles1 -TestResults $results -OutputOnly

--If happy with the dry run, tell the command to fix the issues
$realRun = Reset-DssSecurity @appsplat -Database roles1 -TestResults $results

--Run a final test to check that everything is in line again
$final = Invoke-DssTest @appsplat -Database roles1 -Config $config
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
