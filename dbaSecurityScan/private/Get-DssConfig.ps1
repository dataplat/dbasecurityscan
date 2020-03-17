function Get-DssConfig {
    <#
    .SYNOPSIS
        Gets the test config from the specified folder
    
    .PARAMETER ConfigPath
        Location of the configuration file. May be on a filepath or a URL
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string[]]$ConfigPath
    )
    begin {}
    process {}
    end {
        $objConfig = @()
        Foreach ($config in $ConfigPath){
            if ($config -match '^http.*') {
                $response = Invoke-WebRequest $config
                if ($response.StatusCode -eq '200') {
                    $content = $response.content
                } else {
                    Write-Warning -Message "Could not get content from $config"
                }
            } else {
                if (Test-Path $config) {
                    $content = Get-Content $config -Raw
                } else {
                    Write-Warning -Message "Could not get content from $config"
                }
            }
            $objConfig += ConvertFrom-Json -InputObject $content
        }
            
    }
}