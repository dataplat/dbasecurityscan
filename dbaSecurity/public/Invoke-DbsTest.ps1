function Invoke-DbsTest {
    <#
    .SYNOPSIS
        Runs the specified tests against the specified database(s)
    
    .PARAMETER SqlInstance

    .PARAMETER SqlCredential

    .PARAMETER ConfigPath

    .EXAMPLE
        Invoke-DbsTest -SqlInstance localhost -ConfigPath c:\tests\config.json

    .EXAMPLE
        Invoke-DbsTest -SqlInstance localhost -ConfigPath http://github.com/someone/SqlTest/raw/config.json

    .EXAMPLE
        Invoke-DbsTest -SqlInstance localhost -ConfigPath c:\tests\secrets.json, http://github.com/someone/SqlTest/raw/config.json

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string[]]$ConfigPath,
        [string]$SqlInstance,
        [PSCredential]$SqlCredential
    )
    begin {
        try {
            $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
        }
        catch {
            Write-Warning -Message "Cannot connect to $SqlInstance, stopping"
            return 
        }
    }
    process {
        $config = Get-DbsConfig -ConfigPath $ConfigPath
    }
    end {}
}