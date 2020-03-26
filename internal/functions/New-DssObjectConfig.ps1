Function New-DssObjectConfig {
<#
    .SYNOPSIS
        Creates a new user config section for scanning

        Output dumped to STDOUT 
    
    .PARAMETER SqlInstance
        SQL Server instance holding the databse to be used as the base for the configuration

    .PARAMETER SqlCredential
        A PSCredential object to connect to SqlInstance

    .PARAMETER Database
        Database to use as basis for config
    
    .PARAMETER IncludeSystemObjects
        Switch to include system objects.
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database,
        [switch]$IncludeSystemObjects
    )
    begin {
        if ($IncludeSystemObjects) {
            $exclude = $false
        } else {
            $exclude = $true
        }
    }
    process {}
    end {
        $output = @()

        $objects  = @()

        $objects += Get-DbaDbTable -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database | Select-Object Schema, Name
        $objects += Get-DbaDbView -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -ExcludeSystemView:$exclude | Select-Object Schema, Name 
        $objects += Get-DbaDbStoredProcedure -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -ExcludeSystemSp:$exclude | Select-Object Schema, Name
        $permissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database 
        ForEach ($object in $objects){
            $permission = $permissions | Where-Object {$_.Schema -eq $object.SchemaOwner -and $_.Securable -eq $object.name} | select-Object grantee, permission
            $output += [PSCustomObject]@{
                object = $object.Name
                schema = $object.schema
                permissions = $permission
            }
        }

    $output
    }
} 