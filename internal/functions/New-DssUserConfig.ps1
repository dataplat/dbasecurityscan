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

        $securable = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database | Where-Object {$_.SourceView -eq 'sys.all_objects' -and $_.GranteeType -eq $_.GranteeType -eq 'SQL_USER'}
        $roles= Get-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database

        Foreach ($user in ($securable | Select-Object -unique grantee)){
            Write-Verbose "working on $user"
            $role = $roles | Where-Object {$_.Username -eq $user.grantee} | Select-Object -Property role -unique
            $permissions = $securable | Where-Object {$_.grantee -eq $user.grantee} | Select-Object -Property  schemaowner,securable,permission
            $output += [PsCustomObject]@{username = $user.Grantee
                permissions = $permissions
                roles = $role.role
            }
        }
    $output
    }
} 