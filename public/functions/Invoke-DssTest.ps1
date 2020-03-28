function Invoke-DssTest {
    <#
    .SYNOPSIS
        Runs the specified tests against the specified database(s)
    
    .PARAMETER SqlInstance

    .PARAMETER SqlCredential

    .PARAMETER ConfigPath

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath c:\tests\config.json

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath http://github.com/someone/SqlTest/raw/config.json

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath c:\tests\secrets.json, http://github.com/someone/SqlTest/raw/config.json

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string[]]$ConfigPath,
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string]$Database,
        [switch]$UserConfig,
        [switch]$RoleConfig,
        [switch]$SchemaConfig,
        [switch]$ObjectConfig,
        [object]$config
    )
    begin {

    }
    process {
        # $config = Get-DssConfig -ConfigPath $ConfigPath

        $srv = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential


        $configSwitch = $true
        if ($UserConfig -or $SchemaConfig -or $RoleConfig -or $ObjectConfig) {
            $configSwitch = $false
        }
        if ($UserConfig -or $configSwitch) {
            Write-Verbose -Message "Testing User config"
            Invoke-Pester -Script @{ Path = "$PSModuleRoot\checks\Users.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} }
        } 
        if ($RoleConfig -or $configSwitch) {
            Write-Verbose -Message "Testing Role config"
            Invoke-Pester -Script @{ Path = "$PSModuleRoot\checks\Roles.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} }
        } 
        if ($SchemaConfig -or $configSwitch) {
            Write-Verbose -Message "Testing Schema config"
            Invoke-Pester -Script @{ Path = "$PSModuleRoot\checks\Schemas.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} }
        } 
        if ($ObjectConfig -or $configSwitch) {
            Write-Verbose -Message "Testing Object config"
            Invoke-Pester -Script @{ Path = "$PSModuleRoot\checks\Objects.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} }
            }
    }
    end {}
}