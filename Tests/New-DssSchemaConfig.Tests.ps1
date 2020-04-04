$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-host "importing $PSScriptRoot/constants.ps1 "
. "$PSScriptRoot\constants.ps1"

Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration Tests for $commandName" {
    $config = New-DssSchemaConfig -SqlInstance $script:appvSqlInstance -SqlCredential $script:appvSqlCredential -Database schema1

    Write-host "-------------------------"
    Write-Host "$config"
    Write-host "-------------------------"

    Foreach ($c in $config){
        if($c.schemaname -eq 'unowned'){
            foreach ($o in $config.objects) {
                It "see $.object exists"{
                    1 | Should -Be 1
                }
            }
        }
    }
    $sConfig = [PsCustomObject]@{
        schemas = $config
    }

    It "Should Test db properly" {
        $pesterOut = Invoke-Pester -Script @{ Path = "$PSScriptRoot\..\Checks\Schemas.Tests.ps1"; Parameters = @{SqlInstance = $script:appvSqlInstance; Config = $sConfig; SqlCredential = $script:appvSqlCredential; Database = "schema1"} } -PassThru
        $pesterOut.PassedCount | Should -Be $pesterOut.TotalCount
    }
}