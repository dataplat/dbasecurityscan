$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-host "importing $PSScriptRoot/constants.ps1 "
. "$PSScriptRoot\constants.ps1"

Describe "Unit tests for $commandName"{
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration Tests for $commandName" {
    $config = New-DssUserConfig -SqlInstance $script:appvSqlInstance -SqlCredential $script:appvSqlCredential -Database normal1

    It "Should have users" {
        ($config | Measure-Object).count | Should -Be 6
    }

    $pConfig = [PsCustomObject]@{
        users = $config
    }

    It "Should Test db properly" {
        $pesterOut = Invoke-Pester -Script @{ Path = "$PSScriptRoot\..\Checks\Users.Tests.ps1"; Parameters = @{SqlInstance = $script:appvSqlInstance; Config = $pConfig; SqlCredential = $script:appvSqlCredential; Database = "normal1"} } -PassThru
        $pesterOut
        $pesterOut.PassedCount | Should -Be $pesterOut.TotalCount
    }
}