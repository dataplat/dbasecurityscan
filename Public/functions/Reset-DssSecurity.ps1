function Reset-DssSecurity {
    <#
    .SYNOPSIS
        Resets the security on the specified databaase
    
    .PARAMETER SqlInstance

    .PARAMETER SqlCredential

    .PARAMETER TestResults

    .EXAMPLE


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
        [switch]$OutputOnly,
        [switch]$AddOnly,
        [switch]$RemoveOnly, 
        [object]$TestResults,
        [switch]$Quiet,
        [switch]$IncludeSystemObjects
    )
    begin{}
    process{}
    end{

        $configSwitch = $true
        if ($UserConfig -eq $True -or $SchemaConfig -eq $True -or $RoleConfig -eq $True -or $ObjectConfig -eq $True) {
            $configSwitch = $false
        }

        if ($UserConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Resetting User config"
            $usersFixResults = Reset-DssUserSecurity -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -TestResults $TestResults -OutputOnly:$OutputOnly -AddOnly:$AddOnly -RemoveOnly:$RemoveOnly
        } 
        if ($RoleConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Resetting Role config - not implelemented yet"
            # $rolesFixResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Roles.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database } } -PassThru -Show $show
        } 
        if ($SchemaConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Resetting Schema config"
            $schemaFixResults = Reset-DssSchemaSecurity -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -TestResults $TestResults -OutputOnly:$OutputOnly -AddOnly:$AddOnly -RemoveOnly:$RemoveOnly
        } 
        if ($ObjectConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Resetting Object config - not implelemented yet"
            # $objectFixResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Objects.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database } } -PassThru -Show $show
        }
 
        $usersFixResults
        $schemaFixResults


    }
}
    