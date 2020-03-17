param (
    [object]$config,
    [Object]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

$connectionSplat = @{
            SqlInstance  = $SqlInstance
            SqlCredential = $SqlCredential
            Database      = $Database
}

$sqlSchema = "
        select 
            ss.name as 'schemaName', 
            sdp.name as 'owner' 
        from 
            sys.schemas ss inner join sys.database_principals sdp 
                on ss.principal_id=sdp.principal_id
"
$dbSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database "schema1" -Query $sqlSchema 

Foreach ($schema in $config.schemas) {
    Describe "Checking schema $($schema.schemaname)" {
        It "Schema $($schema.schemaname) should exist and be owned by $($schema.owner)" {
            ($dbSchema | Where-Object {$_.schemaName -eq $schema.schemaname -and $_.owner -eq $schema.owner}).count | Should -Be 1
        }
        $checkSql = "select name, type_desc from sys.all_objects where schema_id=SCHEMA_ID('$($schema.schemaname)')"
        $objectsSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database "schema1" -Query $checkSql 
            
        It "Schema $($schema.schemaname) should contain $($schema.objects.count) Objects" {
            $objectsSchema.count | Should -Be $schema.objects.count -Because "The schema should only contain the specified objects"
        }

        Foreach ($object in  $schema.objects) {
            It "$($schema.schemaname) should contain $($object.object)"{
                ($objectsSchema | Where-Object {$_.name -eq $object.Object }).count | Should -Be 1
            }
        }
    }
}
