Function Reset-DssSchemaSecurity {
    <#
    .SYNOPSIS
        Resets a databases Schema lever permissions to the defined state
    
    .PARAMETER SqlInstance
        SQL Server instance holding the databse to be used as the base for the configuration

    .PARAMETER SqlCredential
        A PSCredential object to connect to SqlInstance

    .PARAMETER Database
        Database to use as basis for config
    
    .PARAMETER TestResult
        Output from Invoke-DssTest
    
    .PARAMETER RemoveOnly
        Switch will only remove extra objects from database

    .PARAMETER AddOnly
        Switch will only add missing objects to database

    .PARAMETER OutputOnly
        Switch will cause no actions to happen, output of what would happen will be returned.

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database,
        [object]$TestResults,
        [switch]$OutputOnly,
        [switch]$AddOnly,
        [switch]$RemoveOnly 
    )
    begin {
        
    }
    process { }
    end {
        $errors = $TestResults.SchemaResults.TestResult | Where-Object { $_.Result -eq 'Failed' }
        ForEach ($err in $errors) {
            Write-Verbose "$($err.name)"

            If ($err.Name -match "Schema (.*) should exist" -and $RemoveOnly.IsPresent -ne $true){
                Write-Verbose "Schema $($Matches[1]) is missing"
                # Create Schema
                $createSql = "CREATE SCHEMA $($Matches[1])"
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Add"
                    Resolution  = "Create Schema owned by dbo"
                    SqlQuery    = $createSql
                    dbatools    = $null 
                }
                if ($OutputOnly -ne $true){
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $createSql
                }
            }

            if ($err.Name -match "Schema (.*) should be owned by (.*)" -and $RemoveOnly.IsPresent -ne $true) {
                Write-Verbose "Schema $($Matches[1]) not owned by $($Matches[2]), change owner"
                # ReAssign Schema
                $authorizeSql = "ALTER AUTHORIZATION ON SCHEMA::$($Matches[1]) TO $($Matches[2])"
                Write-Verbose $authorizeSql
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Add"
                    Resolution  = "Reassign scheme to correct owner"
                    SqlQuery    = $authorizeSql
                    dbaTools    = $null  
                         
                }
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $authorizeSql
                }
            }


            if ($err.name -match "Principal (.*) Should have (.*) permission on schema (.*) \(Config\)" -and $RemoveOnly.IsPresent -ne $true) {
                Write-Verbose "Missing permission , $($Matches[1]) Should have $($Matches[2]) permission on schema $($Matches[3]) adding"
                # Grant Permission
                $grantSql = "GRANT $($Matches[2]) ON SCHEMA::$($Matches[3]) TO $($Matches[1])"
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Add"
                    Resolution  = "Granting permission on schema"
                    SqlQuery    = $grantSql
                    dbaTools    = $null   
                }
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $grantSQL
                }
            }

            if ($err.name -match "Schema (.*) should be in config \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Schema $($Matches[1]) not in config, removing from db "
                $dropSql = "DROP SCHEMA $($Matches[1])"
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Drop"
                    Resolution  = "Dropping Schema"
                    SqlQuery    = $dropSql
                    dbaTools    = $null        
                }
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $dropSql
                }

            }

            if ($err.name -match "Database object (.*) - (.*) in (.*) should be in config \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Object in schema being removed."
                # Drop Schema
                $dropSql = "DROP $($matches[1]) $($matches[3]).$($matches[2])"
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Drop"
                    Resolution  = "Dropping Object"
                    SqlQuery    = $dropSql
                    dbaTools    = $null          
                }
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $dropSql
                }
            }

            if ($err.name -match "Principal (.*) should have (.*) permission on schema (.*) \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Permission granted on Schema that's not in config, removing"
                # Revoke permission
                $revokeSql = "REVOKE $($Matches[2]) ON SCHEMA::$($Matches[3]) FROM $($Matches[1])"
                [PsCustomObject]@{
                    Type        = "Schema Error"
                    Error       = $err.Name
                    Action      = "Drop"
                    Resolution  = "Revoke schema level permission"
                    SqlQuery    = $revokeSql
                    dbaTools    = $null      
                }

                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $revokeSQL
                }
            }
        }
    }
}