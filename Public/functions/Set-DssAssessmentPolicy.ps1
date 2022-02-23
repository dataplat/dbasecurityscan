function Set-DssAssessmentPolicy {
    <#
    .SYNOPSIS
        Modifies the Assessment Policies in a DSS config object. Allows the user to enable or disable the individual policies

    .PARAMETER Config
        The DSS Config object to be modified

    .PARAMETER PolicyName
        The policy to be modified

    .PARAMETER Enforcing
        Set True to enforce the policy
        Set False to disable the policy

    .EXAMPLE
        Set-DssAssessmentPolicy -Config $c -PolicyName NoUserPermissions -Enforcing $true

        will set the NoUserPermissions policy active 

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [object]$Config,
        [string[]]$PolicyName,
        [bool]$Enforcing
    )
        $policy = $Config.Policy | Where-Object {$_.Name -eq $PolicyName}
        if ($null -ne $policy) {
            $Policy.Enabled = $Enforcing
        } else {
            Write-Error "Specified policy ($PolicyName) does not exist"
        }

}
