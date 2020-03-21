$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "Unit tests for $commandName"{
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Itnegration Tests for $commandName" {
    $password = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $sqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $password)
    $config = New-DssUserConfig -SqlInstance $sqlInstance -SqlCredential $sqlCredential -Database normal1

    It "Should have returned a PSCustomObject"{
        $config | Should -BeOfType [PSCustomObject]
    }

    It "Should have users" {
        $config.Users.count | Should -HaveCount 2
    }

}