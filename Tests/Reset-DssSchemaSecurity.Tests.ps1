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
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
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

    Context "Test fixing schema ownership" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query "ALTER AUTHORIZATION ON SCHEMA::deleteable to schemaOwner"
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
        $checkSql = "select count(1) as 'count' from sys.schemas where name='deleteable' and principal_id=user_id('dbo')"
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema deleteable Should not be owned by dbo before test" {
            $checkResult.count | Should -Be 0
        }
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema deleteable Should be owned by dbo post test" {
            $checkResult.count | Should -Be 1
        }
    }

    Context "Test adding schema level permission" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig
        $breakSql = "REVOKE select ON SCHEMA::unowned FROM test;"
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query $breakSql
        $checkSql = "
            select 
                count(1) as 'count'
            from 
                sys.database_permissions sdperm 
                    inner join sys.schemas ss on sdperm.major_id=ss.schema_id
                    inner join sys.database_principals sdp on sdperm.grantee_principal_id = sdp.principal_id
            where class_desc='SCHEMA' and ss.name='unowned' and sdp.name='test'
        "
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Principal test Should not have Select on unowned schema" {
            $checkResult.count | Should -Be 0
        }
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Principal test Should  have Select on unowned schema" {
            $checkResult.count | Should -Be 1
        }
    }

    Context "Test removing extraneous schema" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig
        $breakSql = "CREATE SCHEMA unwanted"
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query $breakSql
        $checkSql = "
            select 
              count(1) as 'count'
            from 
              sys.schemas ss 
            where 
              ss.name='unwanted' 
        "
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema unwanted should exist before test" {
            $checkResult.count | Should -Be 1
        }
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema unwanted should not exist after test" {
            $checkResult.count | Should -Be 0
        }
    }

    Context "Test removing extraneous object from schema" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig
        $breakSql = "CREATE PROCEDURE owned.sp_pester as select * from sys.all_objects"
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query $breakSql
        $checkSql = "
                select 
                    count(1) as 'count' 
                from 
                    sys.all_objects 
                where 
                    name='sp_pester' 
                    and schema_id=SCHEMA_ID('owned')
        "
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema unwanted should exist before test" {
            $checkResult.count | Should -Be 1
        }
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Schema unwanted should not exist after test" {
            $checkResult.count | Should -Be 0
        }
    }

    Context "Test removing extraneous permissions from schema" {
        $config = New-DssConfig @script:appsplat -database $script:database -SchemaConfig 
        # -IncludeSystemObjects
        $breakSql = "GRANT ALTER ON SCHEMA::owned TO test"
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query $breakSql
            $checkSql = "
                select 
                    count(1) as 'count'
                from 
                    sys.database_permissions sdperm 
                        inner join sys.schemas ss on sdperm.major_id=ss.schema_id
                        inner join sys.database_principals sdp on sdperm.grantee_principal_id = sdp.principal_id
                where 
                    class_desc='SCHEMA' and 
                    ss.name='owned' and 
                    sdp.name='test' and 
                    sdperm.permission_name='ALTER'
            "
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Grant should exist before test" {
            $checkResult.count | Should -Be 1
        }
        $results = Invoke-DssTest @script:appsplat -database $script:database -SchemaConfig -Config $config -Quiet
        Reset-DssSchemaSecurity @script:appsplat -database $script:database -TestResult $results
        $checkResult = Invoke-DbaQuery @script:appsplat -Database $script:database -Query $checkSql
        It "Grant should not exist after test" {
            $checkResult.count | Should -Be 0
        }
    }
}