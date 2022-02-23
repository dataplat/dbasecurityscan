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

    .PARAMETER IncludeSystemObjects
        By default the object config does not include system objects. This switch overrides that and returns all objects

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
        [string]$ConfigPath,
        [string]$Database,
        [switch]$UserConfig,
        [switch]$RoleConfig,
        [switch]$SchemaConfig,
        [switch]$ObjectConfig,
        [switch]$IncludeSystemObjects
    )
    begin {}
    process {}
    end {
        $policies = Get-DssAssessmentPolicy
        ForEach ($policy in $Policies){
            $Policy | Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $false
        }
        $configSwitch = $true
        if ($UserConfig -or $SchemaConfig -or $RoleConfig -or $ObjectConfig){
            $configSwitch = $false
        }
        if ($UserConfig -or $configSwitch) {
            Write-Verbose -Message "Fetching User config"
            $configUser = New-DssUserConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        } 
        if ($RoleConfig -or $configSwitch) {
            Write-Verbose -Message "Fetching Role config"
            $configRole = New-DssRoleConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
        } 
        if ($SchemaConfig -or $configSwitch) {
            Write-Verbose -Message "Fetching Schema config"
            $configSchema = New-DssSchemaConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -IncludeSystemObjects:$IncludeSystemObjects
        } 
        if ($ObjectConfig -or $configSwitch) {
            Write-Verbose -Message "Fetching Object config"
            $configObject = New-DssObjectConfig -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -IncludeSystemObjects:$IncludeSystemObjects
        }
        $internalConfig = [PsCustomObject]@{
                    SystemObjects   = if($IncludeSystemObjects -eq $true ){$True} else {$False}
                    Generated       = Get-Date
                    Database        = $Database
                    SqlInstance     = $SqlInstance
                }   

        $output = [PsCustomObject]@{
                    policy  = $policies
                    config  = $internalConfig
                    roles   = $configRole
                    users   = $configUser
                    schemas = $configSchema
                    objects = $configObject
        } 

        if ($ConfigPath -ne ''){
            $output | ConvertTo-Json -Depth 7 | Out-File $ConfigPath
        } else {
            $output
        }
    }
}