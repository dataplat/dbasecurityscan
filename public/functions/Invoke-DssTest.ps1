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
        [string]$Database
    )
    begin {
        # try {
        #     $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
        # }
        # catch {
        #     Write-Warning -Message "Cannot connect to $SqlInstance, stopping"
        #     return 
        # }
    }
    process {
        $config = Get-DssConfig -ConfigPath $ConfigPath
        Invoke-Pester -Script @{ Path =  "$PSModuleRoot\checks\Users.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; Config= $config; Database=$database} }
    }
    end {}
}