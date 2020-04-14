param (
    [object]$config,
    [Object]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database,
    [switch]$IgnoreConfigCheck,
    [Switch]$IgnoreDatabaseCheck,
    [Switch]$IncludeSystemObjects
)
if ($config.config.SystemObjects -ne $true -and $IncludeSystemObjects -ne $true) {
    $sqlSystemFilter = 1
} else {
    $sqlSystemFilter = 2
}

if ($IgnoreConfigCheck -ne $true) {
    Describe "Testing Schema config against database" {
        # FIXME: Potential dbatools command to migrate across. Get Schema details
        $sqlSchema = "
                select 
                    ss.name as 'schemaName', 
                    sdp.name as 'owner' 
                from 
                    sys.schemas ss inner join sys.database_principals sdp 
                        on ss.principal_id=sdp.principal_id
        "
        $dbSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $sqlSchema 

        $testPermissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest 
        Foreach ($schema in $config.schemas) {
            Context "Checking schema $($schema.schemaName) (Config)" {
                # Test Schema exists

                It "Schema $($schema.schemaName) should exist" {
                    ($dbSchema | Where-Object { $_.schemaName -eq $schema.schemaname} | Measure-Object).count | Should -Be 1

                }
                It "Schema $($schema.schemaName) should be owned by $($schema.owner)" {
                    ($dbSchema | Where-Object {$_.schemaName -eq $schema.schemaname -and $_.owner -eq $schema.owner} | Measure-Object).count | Should -Be 1
                }


                $checkSql = "select 
                                name, 
                                type_desc 
                            from 
                                sys.all_objects 
                            where 
                                schema_id=SCHEMA_ID('$($schema.schemaname)') 
                                and is_ms_shipped<$sqlSystemFilter" 

                $objectsSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $checkSql 
                
                # Test for schema objects 
                Foreach ($object in  $schema.objects) {
                    It "$($schema.schemaname) should contain $($object.object) (Config)" {
                        ($objectsSchema | Where-Object {$_.name -eq $object.Object } | Measure-Object).count | Should -Be 1
                    }
                }

                # Test permissions on Schema
                Foreach ($permission in $schema.permissions){
                    It "Principal $($permission.grantee) Should have $($permission.permission) permission on schema $($schema.schemaName) (Config)" {
                        ($testPermissions | Where-Object {$_.Grantee -eq $permission.grantee -and $_.Permission -eq $permission.permission -and $_.Securable -eq $schema.schemaName -and $_.RoleSecurableClass -eq 'SCHEMA'} | Measure-Object).count | Should -Be 1
                    }
                }
            }
        }

    }
}

if ($IgnoreDatabaseCheck -ne $True) {
    Describe "Testing database against config" {

        # FIXME: Potential dbatools command to migrate across. Get Schema details
        $sqlSchema = "
                select 
                    ss.name as 'schemaName', 
                    sdp.name as 'owner' 
                from 
                    sys.schemas ss inner join sys.database_principals sdp 
                        on ss.principal_id=sdp.principal_id
        "
        $dbSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $sqlSchema 
        $schemaPermissions = Get-DbaUserPermission -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -IncludeSystemObjects:$IncludeSystemObjects
        #  $schemaPermissionSql = "
        #                 select 
        #                     ss.name as 'SchemaName',
        #                     sdperm.permission_name as 'Permission',
        #                     USER_NAME(sdp.principal_id) as 'Grantee'
        #                 from 
        #                     sys.database_permissions sdperm 
        #                         inner join sys.schemas ss on sdperm.major_id=ss.schema_id
        #                         inner join sys.database_principals sdp on sdperm.grantee_principal_id = sdp.principal_id
        #                 where class_desc='SCHEMA'
        # "
        # $schemaPermissions = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $schemaPermissionSql
        Foreach ($schema in $dbSchema) {
            Context "Checking schema $($schema.schemaname) (DB)" {

                # Test DB Schema is in config
                It "Schema $($schema.schemaName) should be in config (DB)" {
                    $schema.schemaName -in $config.schemas.schemaName | Should -BeTrue
                }


                $checkSql = "select 
                                name,                             
                                case 
                                    when sa.type_desc = 'SQL_STORED_PROCEDURE' THEN 'PROCEDURE'
                                    when sa.type_desc like '%FUNCTION%' THEN 'FUNCTION'
                                    else sa.type_desc
                                end as 'type'
                            from 
                                sys.all_objects sa
                            where 
                                schema_id=SCHEMA_ID('$($schema.schemaname)')
                                and sa.is_ms_shipped<$sqlSystemFilter"

                $objectsSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $checkSql 

                # Check DB Schema Objects are in config.
                ForEach ($object in $objectsSchema){
                    It "Database object $($object.type) - $($object.name) in $($Schema.schemaname) should be in config (DB)"{
                        $object.name -in ($config.schemas | Where-Object { $_.schemaname -eq $schema.schemaname }).objects.object | Should -BeTrue
                    }
                }
                $configPermissions = ($config.schemas | Where-Object {$_.schemaname -eq $schema.schemaname }).permissions 
                
                # Check DB permissions on Schema against config
                ForEach ($permission in $schemaPermissions | Where-Object { $_.SchemaName -eq $schema.schemaName }) {
                    It "Principal $($permission.Grantee) should have $($permission.permission) permission on schema $($schema.schemaName) (DB)" {
                        ($permission | Where-Object {$_.Grantee -eq $confingPermissions.Grantee -and $_.Permission -eq $configPermissions.Permission} | Measure-Object).count | Should -Be 1
                    }
                }
            }            
        }
    }
}