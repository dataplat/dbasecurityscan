$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"


Describe "Integration Tests for $commandName" {
    $config = New-DssConfig -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -UserConfig
    $output = Invoke-DssTest -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -config $config -Output
    $noOutput = Invoke-DssTest -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -config $config -WarningVariable warnvar -ErrorVariable errvar 
    It "Should Run with no warnings" {
        '' -eq $warnvar | Should -BeTrue
    }

    It "Should have returnd no output with no output switch set " {
        $null -eq $noOutput | Should -Be True
    }

    It "Should have returned output with the output set"{
        $output.count -gt 0 | Should -Be True
    }

    AfterAll {
        # Reset normal1 database
        $query = get-Content '.\Tests\scenarios\normal1\normal1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -Confirm:$false
        (Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential).Databases['master'].ExecuteNonQuery($query)
    }
}