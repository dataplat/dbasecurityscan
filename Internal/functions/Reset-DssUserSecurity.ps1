Function Reset-DssUserSecurity {
<#
    .SYNOPSIS
        Resets a databases User lever permissions to the defined state
    
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
    process {}
    end {
        $errors = $TestResults.UsersResults.TestResult | Where-Object {$_.Result -eq 'Failed'}
        ForEach ($err in $errors){
            write-verbose "$($err.name)"
            if ($err.Name -match 'Database user (.*) should be in config' -and $AddOnly -ne $True) {
                write-verbose "Removing additional db user $($Matches[1])"
                $dropSql = "DROP USER $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    if ($IsCoreCLR) {
                        # Due to a flaw in .NETcore, Remove-DbaUser won't work in PsCore :(, so we have to use T-SQL. Remove once it's fixed.
                        Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $dropSql
                    } else {
                        Remove-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Confirm:$false -ErrorAction SilentlyContinue
                    }
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Removing User"
                    SqlQuery   = $dropSql
                    dbatools   = "Remove-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Confirm:$false -ErrorAction SilentlyContinue"
                }
            }
            
            if ($err.Name -match '(.*) should be a member of (.*) \(Config\)' -and $RemoveOnly -ne $True) {
                Write-Verbose "adding $($matches[1]) to role $($matches[2])"
                if ($OutputOnly -ne $true)  {
                    Add-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Role $Matches[2] -Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Add user to Role"
                    SqlQuery   = $null
                    dbatools   = "Add-DbaDbRoleMember -SqlInstance $($SqlInstance) -SqlCredential $($SqlCredential) -Database $($database) -User $($Matches[1]) -Role $($Matches[2]) -Confirm:$false"
                }
            }

            if ($err.Name -match '$($case.username) Should be in $($role.Role) (DB)' -and $AddOnly -ne $True) {
                Write-Verbose "removing $($matches[1]) from role $($matches[2])"
                if ($OutputOnly -ne $true) {
                    Remove-DbaDbRoleMember -SqlInstance $sqlInstance -SqlCredential $SqlCredential  -Database $database -User $Matches[1] -Role $Matches[2] -Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Remove user from Role"
                    SqlQuery   = $null
                    dbatools   = "Remove-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $($Matches[1]) -Role $($Matches[2]) -Confirm:$false"
                }
            }
            if ($err.Name -match 'Should have assigned (.*) permission (.*) on (.*) in (.*)' -and $RemoveOnly -ne $True) {
                Write-Verbose "Granting 'GRANT $($Matches[2]) on $($Matches[4]).$($Matches[3]) to $($Matches[1])' "
                $grantSql = "GRANT $($Matches[2]) on $($Matches[4]).$($Matches[3]) TO $($Matches[1])"
                if ($OutputOnly -ne $True) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $grantSql -Verbose
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Grant permissions on object to user"
                    SqlQuery   = $grantSql
                    dbatools   = $null
                }
            }
            if ($err.Name -match 'User (.*) Should Only have (.*) on (.*) in (.*)' -and $AddOnly -ne $True) {
                Write-Verbose "Revoking 'REVOKE $($Matches[2]) on $($Matches[4]).$($Matches[3]) to $($Matches[1])' "
                $revokeSql = "REVOKE $($Matches[2]) on $($Matches[4]).$($Matches[3]) FROM $($Matches[1])"
                if ($OutputOnly -ne $True) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $revokeSql -Verbose
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Revoke object permission from user"
                    SqlQuery   = $revokesql
                    dbatools   = $null
                }
            }

            if ($err.name -match "Should have assigned (.*) permission (.*) on schema (.*)" -and $RemoveOnly -ne $True) {
                Write-Verbose "Granting 'GRANT $($Matches[2]) on schema $($Matches[3]) to $($Matches[1])' "
                $grantSql = "GRANT $($Matches[2]) on schema::$($Matches[3]) TO $($Matches[1])"
                if ($OutputOnly -ne $True) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $grantSql -Verbose
                }
                [PsCustomObject]@{
                    Type       = "User Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Grant permissions on schema to user"
                    SqlQuery   = $grantSql
                    dbatools   = $null
                }
            }
            if ($err.Name -match '(.*)should exist in database') {
                # Need to sort out login names
            }
        }
    }
}