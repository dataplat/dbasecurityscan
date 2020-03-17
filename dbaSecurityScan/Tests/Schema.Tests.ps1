param (
    [object]$config,
    [Object]$SqlInstance,
    [SecureString]$SqlCredential,
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
$dbSchema = Invoke-DbaQuery @connectionSplat -Query $sqlSchema
Foreach ($schema in $config.schema) {
    It "Schema $($schema.schemaname)should exist and be owned by $($schema.owner) in database" {
        ($dbSchema | Where-Object ($_.schemaName -eq $schema.schemaname -and $_.owner -eq $schema.owner)).count | Should -Be 1
    }

}
