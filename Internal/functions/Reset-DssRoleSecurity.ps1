Function Reset-DssRoleSecurity {
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
        $errors = $TestResults.RolesResults.TestResult | Where-Object { $_.Result -eq 'Failed' }
        ForEach ($err in $errors) {
            Write-Verbose "$($err.name)"
            if ($err.Name -match "Role (.*) Should Exist \(Config\)" -and $RemoveOnly.IsPresent -ne $true){
                Write-Verbose "Adding missing role $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    $null = New-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $Matches[1] Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Adding Role"
                    SqlQuery   = $null
                    dbatools   = "New-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $($Matches[1])"
                }
            } elseif ($err.Name -match "User (.*) Should be a member of role (.*) \(Config\)" -and $RemoveOnly.IsPresent -ne $true) {
                Write-Verbose "Adding user $($Matches[1]) to role $($Matches[2])"
                if ($OutputOnly -ne $true) {
                    Add-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $Matches[2] -User $Matches[1] -Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Adding User to Role"
                    SqlQuery   = $null
                    dbatools   = "Add-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $($Matches[2]) -User $($Matches[1])"
                } 
            } elseif ($err.Name -match "Role (.*) Should have (.*) on (.*) \(Config\)" -and $RemoveOnly.IsPresent -ne $true) {
                Write-Verbose "Granting permission $($Matches[2]) on object $($Matches[3]) to role $($Matches[1])"
                $grantSql = "GRANT $($Matches[2]) on $($Matches[3]) to $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $grantSQL
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Granting permission to role"
                    SqlQuery   = $grantSql
                    dbatools   = $null
                } 
            } elseif ($err.Name -match "Role (.*) Should Be in config \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Removing role $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    Remove-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $Matches[1] -Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Remove Role"
                    SqlQuery   = $null
                    dbatools   = "Remove-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $($Matches[1])"
                } 

            } elseif ($err.Name -match "Rolemember (.*) Should Be in role (.*) \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Removing $($Matches[1]) from Role $($Matches[2])"
                $grantSql = "GRANT $($Matches[2]) on $($Matches[3]) to $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    Remove-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $matches[2] -User $Matches[1] -Confirm:$false
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Removing User from Role"
                    SqlQuery   = $null
                    dbatools   = "Remove-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Role $($matches[2]) -User $($Matches[1])"
                } 
            } elseif ($err.Name -match "Role (.*) should have (.*) on (.*) in schema (.*) \(DB\)" -and $AddOnly.IsPresent -ne $true) {
                Write-Verbose "Revoking permission $($Matches[2]) on object $($Matches[3]) from role $($Matches[1])"
                $grantSql = "Revoke $($Matches[2]) on $($Matches[3]) from $($Matches[1])"
                if ($OutputOnly -ne $true) {
                    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $grantSQL
                }
                [PsCustomObject]@{
                    Type       = "Role Error"
                    Error      = $err.Name
                    Action     = "Drop"
                    Resolution = "Revoking permission from role"
                    SqlQuery   = $grantSql
                    dbatools   = $null
                } 
            }
        }
    }
}

    
