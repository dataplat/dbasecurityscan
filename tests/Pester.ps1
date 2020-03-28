param (
    $Show = "None"
)

Write-Host "Starting Tests" -ForegroundColor Green
if ($env:BUILD_BUILDURI -like "vstfs*") {
    Write-Host "Installing Pester" -ForegroundColor Cyan
    Install-Module Pester -Force -SkipPublisherCheck
    Write-Host "Installing PSFramework" -ForegroundColor Cyan
    Install-Module PSFramework -Force -SkipPublisherCheck
    Write-Host "Installing dbatools" -ForegroundColor Cyan
    Install-Module dbatools -Force
}

Write-Host "Loading constants"
. "$PSScriptRoot\constants.ps1"

Write-Host "Building Test Scenarios"
$sqlInstance = 'localhost\sql2017'
if ($script:IgnoreSQLCMD) {
    $srv = Connect-DbaInstance -SqlInstance $script:appvSqlInstance -SqlCredential $script:appvSqlCredential
    ForEach ($file in (Get-ChildItem "$PSScriptRoot\scenarios" -File -Filter "*.sql" -recurse)) {
        $c = Get-Content $file -Raw
        $srv.Databases['master'].ExecuteNonQuery($c)
        # (& sqlcmd -S "$sqlInstance" -U "sa" -P "Password12!" -b -i "$($file.fullname)" -d "master")
    }
} else {
    ForEach ($file in (Get-ChildItem "$PSScriptRoot\scenarios" -File -Filter "*.sql" -recurse)){
        (& sqlcmd -S "$sqlInstance" -U "sa" -P "Password12!" -b -i "$($file.fullname)" -d "master")
    }
}
Write-Host "Importing dbaSecurityScans"
Import-Module "$PSScriptRoot\..\dbaSecurityScan.psd1"

$totalFailed = 0
$totalRun = 0

$testresults = @()
Write-Host "Running individual tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot" -File -Filter "*.Tests.ps1" -Recurse)) {
    Write-Host "Executing $($file.Name)"
    $testResultsFile = ".\TestsResults.xml"
    $results = Invoke-Pester -Script $file.FullName -Show None -PassThru -OutputFormat NUnitXml -OutputFile $testResultsFile
    foreach ($result in $results) {
        $totalRun += $result.TotalCount
        $totalFailed += $result.FailedCount
        # $result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
        $result.TestResult | Where-Object { $true } | ForEach-Object {
            $name = $_.Name
            $testresults += [pscustomobject]@{
                Describe = $_.Describe
                Context  = $_.Context
                Name     = "It $name"
                Result   = $_.Result
                Message  = $_.FailureMessage
            }
        }
    }
}

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List
if ($null -ne $env:APPVEYOR_JOB_ID){
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
}
if ($totalFailed -gt 0) {
    throw "$totalFailed / $totalRun tests failed"
}