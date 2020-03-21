$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "Unit tests for $commandName"{
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration Tests for $commandName" {
    $password = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $sqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $password)
    $config = New-DssUserConfig -SqlInstance $sqlInstance -SqlCredential $sqlCredential -Database normal1


    It "Should have users" {
        $config.Users | Should -HaveCount 2
    }

    It "Should Test db properly" {
        Invoke-Pester -Script @{ Path =  "$PSModuleRoot\checks\Users.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; Config= $config; Database="normal1"} } | Should -BeTrue
    }
}