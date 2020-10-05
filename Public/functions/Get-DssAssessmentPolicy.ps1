function Get-DssAssessmentPolicy {
    $files = Get-ChildItem "$Script:dssmoduleroot\Checks\Policies" -filter *.ps1
    foreach ($file in $files){
        [PSCustomObject]@{
            Name        = $file.BaseName -replace '.Tests',''
            Description = Get-Content $file | Where-Object { $_ -like "Description: *" }
            Reason      = Get-Content $file | Where-Object { $_ -like "Reason: *" }
        }
    }
}