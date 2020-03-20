$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "Unit tests for $commandName"{
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}