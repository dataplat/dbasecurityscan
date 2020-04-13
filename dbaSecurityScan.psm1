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