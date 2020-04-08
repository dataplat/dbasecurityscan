$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"
Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration tests for $commandName" {
    $outfile = "$PSScriptRoot\scenarios\normal1\test.json"
    $config = Get-DssConfig -ConfigPath $outfile 
    It "File Config Should Exist" {
        Test-Path $outfile | Should -Be $true
    }
    It "Should get a Config" {
        $config.Config.defaultAccess | Should -Be 'noAccess'
    }
    It "Should have content" {
        ($config.Users | Measure-Object).count | Should -Be 2
        ($config.Users.Roles | Measure-Object).Count | Should -Be 3
    }
}