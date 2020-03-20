$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"
Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}
(& sqlcmd -S localhost\sql2017 -U -b -i "$PSScriptroot\tests\scenarios\normal1\normal1.sql" -d "master")
$sqlinstance = 'localhost\sql2017'
Describe "Integration tests for $commandName" {
    $outfile = 'c:\temp\Userconfig.json'
    Get-DssConfig -SqlInstance $sqlinstance  -Database Normal1 -ConfigPath $outfile -UserConfig
    It "Should get a UserConfig" {
        Test-Path $outfile | Should -Be $true
    }
}