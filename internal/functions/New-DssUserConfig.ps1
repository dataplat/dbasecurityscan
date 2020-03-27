Function New-DssUserConfig {
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
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database
    )
    begin {}
    process {}
    end {
        $output = @()

        $users = Get-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database 
        $securable = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database | Where-Object {$_.SourceView -eq 'sys.all_objects' -and $_.GranteeType -eq $_.GranteeType -eq 'SQL_USER'}
        $roles= Get-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database

        Foreach ($user in ($users)){
            $role = $roles | Where-Object {$_.Username -eq $user.name} | Select-Object -Property role -unique
            $permissions = $securable | Where-Object {$_.grantee -eq $user.name} | Select-Object -Property  schemaowner,securable,permission
            $output += [PsCustomObject]@{username = $user.name
                permissions = $permissions
                roles = $role.role
            }
        } 

    $output
    }
} 