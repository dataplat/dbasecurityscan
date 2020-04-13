$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"

$script:database = 'schema1'

Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset normal1 database

        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\schema1\schema1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    
        # $config = New-DssConfig @script:appsplat -database $database -UserConfig

    }
    Context "Test Adding a missing schema" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query "DROP SCHEMA deleteable"
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Output -Config $config -Quiet
        $checkSql = "select count(1) as 'count' from sys.schemas where name ='deleteable'"
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema deleteable Should not exist before test" {
            $checkResult.count | Should -Be 0
        }
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema deleteable Should exist post test" {
            $checkResult.count | Should -Be 1
        }
    }
}