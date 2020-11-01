function Get-DssAssessmentPolicy {
    <#
    .SYNOPSIS
        Modifies the Assessment Policies in a DSS config object. Allows the user to enable or disable the individual policies

    .PARAMETER Config
        The DSS Config object to be modified
        If not provided the function will return the policies available from the module

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [object]$Config
    )
    $files = Get-ChildItem "$Script:dssmoduleroot\Checks\Policies" -filter *.ps1
    $policies = @()
    foreach ($file in $files){
        $policies += [PSCustomObject]@{
                Name        = $file.BaseName -replace '.Tests',''
                Description = Get-Content $file | Where-Object { $_ -like "Description: *" }
                Reason      = Get-Content $file | Where-Object { $_ -like "Reason: *" }
            }
    }
    if ($null -ne $config) {
        $config.policy | Select-Object -Property Name, Description, Enabled
    } else {
        $policies
    }
}