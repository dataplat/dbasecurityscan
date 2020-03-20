$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"
Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}
$sqlInstance = 'localhost\sql2017'
(& sqlcmd -S $sqlInstance -b -i "$PSScriptroot\tests\scenarios\normal1\normal1.sql" -d "master")

Describe "Integration tests for $commandName" {
    $outfile = "$PSScriptRoot\tests\scenarios\normal1\test.json'"
    $config = Get-DssConfig -ConfigPath $outfile 
    It "Should get a Config" {
        $config.Count | Should -Be 1
    }
    It "Should have content" {
        $config.Users.Count | Should -Be 2
        $config.Users.Roles.Count | Should -Be 3
    }
}