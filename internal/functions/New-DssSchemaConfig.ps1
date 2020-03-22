function New-DssSchemaConfig {
    <#
    .SYNOPSIS
        Creates a new user config section for scanning

        Output dumped to STDOUT 
    
    .PARAMETER SqlInstance
        SQL Server instance holding the databse to be used as the base for the configuration

    .PARAMETER SqlCredential
        A PSCredential object to connect to SqlInstance

    .PARAMETER Database
        Database to use as basis for config
    #>
    [CmdletBinding()]
    param (
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String]$Database
    )
    
    begin {}
    
    process {}
    
    end {
        $sqlSchema = "
                        select 
                            ss.name as 'schemaName', 
                            sdp.name as 'owner' 
                        from 
                            sys.schemas ss inner join sys.database_principals sdp 
                                on ss.principal_id=sdp.principal_id
                    "
        $dbSchema = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database  -Query $sqlSchema 

        $sqlObject = "
                        select 
                            ss.name as 'schemaname',
                            sdp.name as 'owner',
                            sa.name as 'object'
                        from 
                            sys.schemas ss 
                                inner join sys.all_objects sa on ss.schema_id = sa.schema_id
                                inner join sys.database_principals sdp on ss.principal_id=sdp.principal_id
                        WHERE
                            sa.is_ms_shipped=0
                    "
        $dbObject = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $sqlObject 


        $sqlPermissions = "    
                                select 
                                    sdperm.permission_name as 'permission',
                                    ss.name as 'schemaname',
                                    sdp.name as 'grantee'
                                from 
                                    sys.database_permissions sdperm 
                                        inner join sys.schemas ss on sdperm.major_id=ss.schema_id
                                        inner join sys.database_principals sdp on sdperm.grantee_principal_id = sdp.principal_id
                                where class_desc='SCHEMA'
                            "
        $dbPermissions = Invoke-DbaQuery -SqlInstance $SqlInstance -sqlcredential $sqlcredential -database $database -Query $sqlPermissions 

        $output = @()
        ForEach ($schema in $dbSchema){

            $objects = $dbObject | Where-Object {$_.schemaName -eq $schema.schemaName} | Select-Object -Property owner, object
            $permissions  = $dbPermissions | Where-Object {$_.schemaName -eq $schema.schemaName} | select-Object permission, granteee
            $output +=[PsCustomObject]@{
                schemaName = $schema.schemaName
                owner = $schema.owner
                objects = $objects 
                permissions = $permissions
            }
        }
    $output
    }
}