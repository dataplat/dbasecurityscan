$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-host "importing $PSScriptRoot/constants.ps1 "
. "$PSScriptRoot/constants.ps1"

Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration Tests for $commandName" {
    $config = New-DssRoleConfig -SqlInstance $script:appvSqlInstance -SqlCredential $script:appvSqlCredential -Database roles1

    $sConfig = [PsCustomObject]@{
        schemas = $config
    }

    It "Should Test db properly" {
        $pesterOut = Invoke-Pester -Script @{ Path = "$PSScriptRoot\..\Checks\Roles.Tests.ps1"; Parameters = @{SqlInstance = $script:appvSqlInstance; Config = $sConfig; SqlCredential = $script:appvSqlCredential; Database = "roles1"} } -PassThru
        $pesterOut.PassedCount | Should -Be $pesterOut.TotalCount
    }
}