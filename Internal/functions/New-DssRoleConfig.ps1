function New-DssRoleConfig {
    <#
    .SYNOPSIS
        Creates a new schema config section for scanning

        Output passed to STDOUT as PSCustomObject 
    
    .PARAMETER SqlInstance
        SQL Server instance holding the databse to be used as the base for the configuration

    .PARAMETER SqlCredential
        A PSCredential object to connect to SqlInstance

    .PARAMETER Database
        Database to use as basis for config
    #>
    [CmdletBinding()]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database
    )
    
    begin {}
    
    process {}
    
    end {
        $output = @()
        $roles = Get-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
        $roleMembers = Get-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
        $permissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest

        Foreach ($role in $roles){


            $output += [PSCustomObject]@{
                rolename = $role.name
                owner = $role.owner
                members = $roleMembers | Where-Object {$_.role -eq $role.name} | Select-Object -Property UserName
                permissions = $permissions | Where-Object {$_.Grantee -eq $role.name -and $_.GranteeType -eq 'DATABASE_ROLE'} | Select-Object permission, securable, grantee, schemaOwner -unique
            }
        }
        $output
    }
}