function New-DssConfig {
    <#
    .SYNOPSIS
        Creates a New configuration for a security scan

    .PARAMETER SqlInstance
        SQL Server instance holding the databse to be used as the base for the configuration

    .PARAMETER SqlCredential
        A PSCredential object to connect to SqlInstance

    .PARAMETER Database
        Database to use as basis for config

    .PARAMETER UserConfig
        Switch to indicate you want a user based config

    .PARAMETER SchemaConfig
        Switch to indicate you want a Schema based config

    .PARAMETER ObjectConfig
        Switch to indicate you an Object based config

    .PARAMETER ConfigPath
        Where to save the generated config, if not specified it will go to STDOUT

    .EXAMPLE
        New-DssConfig -SqlInstance local\instance1 -Database db1

        Generates all the config json for db1 on local\instance1

    .EXAMPLE
        New-DssConfig -SqlInstance local\instance1 -Database db1 -UserConfig

        Generates the User config json for db1 on local\instance1

    .EXAMPLE
        New-DssConfig -SqlInstance local\instance1 -Database db1 -UserConfig -SchemaConfig

        Generates the User and Schema config json for db1 on local\instance1
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string[]]$ConfigPath,
        [string]$Database,
        [switch]$UserConfig,
        [switch]$RoleConfig,
        [switch]$SchemaConfig,
        [switch]$ObjectConfig
    )
    begin {}
    process {}
    end {
        $configSwitch = $true
        if ($UserConfig -or $SchemaConfig -or $RoleConfig -or $OjbectConfig){
            $configSwitch = $false
        }
        if ($UserConfig -or $configSwitch) {
            $configUser = New-DssUserConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        } elseif ($RoleConfig -or $configSwitch) {
            $configRole = New-DssRoleConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        } elseif ($SchemaConfig -or $configSwitch) {
            $configSchema = New-DssSchemaConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        } elseif ($ObjectConfig -or $configSwitch) {
            $configObject = New-DSSObjectConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        }

        $output = [PsCustomObject]@{
                    roles = $configRole
                    users = $configUser
                    schema = $configSchema
                    object = $configObject
        } | ConvertTo-Json -Depth 4

        if ($ConfigPath -ne ''){
            $output | Out-File $ConfigPath
        } else {
            $output
        }
    }
}