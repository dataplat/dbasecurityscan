Function Reset-DssObjectSecurity {
    <#
    .SYNOPSIS
        Resets a databases Object lever permissions to the defined state
    
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
    process { }
    end {
        $errors = $TestResults.UsersResults.TestResult | Where-Object { $_.Result -eq 'Failed' }
        ForEach ($err in $errors) {
            Write-Verbose "$($err.name)"
            If (($err.name -matches "(.*) Should have $($perm.permission) on object $($object.schema).$($object.object) \(Object\)") -and $RemoveOnly.IsPresent -ne $true) {
                Write-Verbose "Granting $($Matches[1]) to  $($Matches[0]) on object $($Matches[2]).$($Matches[3])"
                if ($OutputOnly -ne $true) {
                    $sqlQuery = "grant $($Matches[1]) on $($Matches[2]).$($Matches[3]) to $($Matches[0])"
                    $results = Invoke-DbaQuery -SqlInstance $sqlinstance -SqlCredential $sqlCredential -Database $database -Query $sqlQuery

                }
                [PsCustomObject]@{
                    Type       = "Object Error"
                    Error      = $err.Name
                    Action     = "Add"
                    Resolution = "Adding Object Permission"
                    SqlQuery   = $sqlQuery
                    dbatools   = $null
                    results    = $results
                }
            }
        }
    }
}


    