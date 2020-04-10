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
    
    .PARAMETER Remove
        Switch will only remove extra objects from database

    .PARAMETER Add
        Switch will only add missing objects to database

    .PARAMETER Output
 
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database,
        [object]$TestResult,
        [switch]$Output
    )
    begin {

    }
    process {}
    end {
        $errors = $TestResult.UsersResults.TestResult | Where-Object {$_.Result -eq 'Failed'}
        ForEach ($err in $errors){
            write-verbose "$($err.name)"
            if ($err.Name -match 'Database user (.*) should be in config') {
                write-verbose "Removing additional db user $($Matches[1])"
                if ($IsCoreCLR) {
                    # Due to a flaw in .NETcore, Remove-DbaUser won't work in PsCore :(, so we have to use T-SQL. Remove once it's fixed.
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query "DROP USER $($Matches[1])"
                } else {
                    Remove-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Confirm:$false -ErrorAction SilentlyContinue

                }
            }
            if ($err.Name -match '(.*) should be a member of (.*) \(Config\)') {
                Write-Verbose "adding $($matches[1]) to role $($matches[2])"
                Add-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Role $Matches[2] -Confirm:$false
            }
            if ($err.Name -match '$($case.username) Should be in $($role.Role) (DB)'){
                Write-Verbose "removing $($matches[1]) from role $($matches[2])"
                Remove-DbaDbRoleMember -SqlInstance $sqlInstance -SqlCredential $SqlCredential  -Database $database -User $Matches[1] -Role $Matches[2] -Confirm:$false
            }
            if ($err.Name -match 'Should have assigned (.*) permission (.*) on (.*) in (.*)') {
                Write-Verbose "Granting 'GRANT $($Matches[2]) on $($Matches[4]).$($Matches[3]) to $($Matches[1])' "
                Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query "GRANT $($Matches[2]) on $($Matches[4]).$($Matches[3]) TO $($Matches[1])" -Verbose
            }
            if ($err.Name -match 'User (.*) Should Only have (.*) on (.*) in (.*)') {
                Write-Verbose "Revoking 'REVOKE $($Matches[2]) on $($Matches[4]).$($Matches[3]) to $($Matches[1])' "
                Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query "REVOKE $($Matches[2]) on $($Matches[4]).$($Matches[3]) FROM $($Matches[1])" -Verbose
           
            }
            if ($err.Name -match '(.*)should exist in database') {
                # Need to sort out login names
            }
        }
    }
}