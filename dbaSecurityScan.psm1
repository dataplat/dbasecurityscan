$script:ModuleRoot = $PSScriptRoot
$PSModuleRoot = $PSScriptRoot
$script:PSModuleRoot = $PSScriptRoot
$script:dssModuleRoot = $PSScriptRoot

Write-verbose "$PSModuleRoot"
function Import-ModuleFile {
    [CmdletBinding()]
    Param (
        [string]
        $Path
    )

    if ($doDotSource) { . $Path }
    else {
        try {
            $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null)
        }
        catch {
            Write-Warning "Failed to import $Path"
        }
    }
}

#Yoinked from dbachecks until I get the tests to be Pester 4/5 agnostic
if ((Get-Module Pester).Version.Major -eq 5) {
    Write-Verbose -Message "You have Pester version 5 in this session which is not compatible - Let me try to remove it" 

    try {
        Remove-Module Pester -Force
        $CompatibleInstalledPester = Get-Module Pester -ListAvailable | Where-Object { $Psitem.Version.Major -eq 4 } | Sort-Object Version -Descending | Select-Object -First 1 
        Write-Verbose -Message "Removed Version 5 trying to import version $($CompatibleInstalledPester.Version.ToString())"
        Import-Module $CompatibleInstalledPester.Path -Verbose -Scope Global
    }
    catch {
        Write-Error -Message "Failed to remove Pester version 5 or import suitable version - Do you have Version 4* installed ?"
        Break
    }
}
else {
    try {
        $CompatibleInstalledPester = Get-Module Pester -ListAvailable | Where-Object { $Psitem.Version.Major -le 4 -and $Psitem.Version.Major -gt 3 } | Sort-Object Version -Descending | Select-Object -First 1 
        Write-Verbose -Message "Trying to import version $($CompatibleInstalledPester.Version.ToString())"
        Import-Module $CompatibleInstalledPester.Path -Verbose -Scope Global
    }
    catch {
        Write-Error -Message "Failed to import suitable version - Do you have Version 4* installed ?"
        Break
    }
}

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = $true

# Import all internal functions
foreach ($function in (Get-ChildItem ".\Internal\functions\*.ps1")) {
    . Import-ModuleFile -Path $function.FullName
}

# Import all public functions
foreach ($function in (Get-ChildItem ".\Public\functions\*.ps1")) {
    # . Import-ModuleFile -Path $function.FullName
    . $function.fullname
}