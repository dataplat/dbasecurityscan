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
            write-verbose "in loop"
            if ($err.Name -match 'Database user (.*) should be in config') {
                write-verbose "match"
                Remove-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Confirm:$false
            }
            if ($err.Name -match '(.*) should be a member of .* (Config)') {
                Add-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -User $Matches[1] -Role $Matches[2] -Confirm:$false
            }
            if ($err.Name -match 'Should have assigned (.*) permission (.*) on (.*)') {
                Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query "GRANT $($Matches[2]) on $($Matches[3]) to $($Matches[0]"
            }
            if ($err.Name -match '(.*)should exist in database') {
                # Need to sort out login names
            }
        }
    }
}