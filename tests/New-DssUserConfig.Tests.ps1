$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "Unit tests for $commandName"{
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Inegration Tests for $commandName" {
    $sqlInstance = '(local)\sql2017'
    (& sqlcmd -S "$sqlInstance" -U "sa" -P "Password12!" -b -i "$PSScriptroot\scenarios\normal1\normal1.sql" -d "master")
    $password = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $sqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $password)
    $config = New-DssUserConfig -SqlInstance $sqlInstance -SqlCredential $sqlCredential -Database normal1

    It "Should have returned a PSCustomObject"{
        $config | Should -BeOfType PSCustomObject
    }

    It "Should have users" {
        $config.Users.count | Should -BeGreaterThan 1
    } 
}