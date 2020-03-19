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
    
    .PARAMETER ConfigPath
        Where to save the generated config, if not specified it will go to STDOUT
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string[]]$ConfigPath
    )
    begin {}
    process {}
    end {


    }
}