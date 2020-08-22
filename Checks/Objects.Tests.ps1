param (
    [object]$config,
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database,
    [switch]$IncludeSystemObjects
)
        $dbObjects  = @()

        $dbObjects += Get-DbaDbTable -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database | Select-Object Schema, Name
        $dbObjects += Get-DbaDbView -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -ExcludeSystemView:$exclude | Select-Object Schema, Name 
        $dbObjects += Get-DbaDbStoredProcedure -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -ExcludeSystemSp:$exclude | Select-Object Schema, Name
        $permissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -IncludePublicGuest
    
        Foreach ($object in $config.objects){
            Describe "Checking $($object.object)" {
                It "$($object.schema).$($object.object) Should exist (Config)" {
                    ($dbObjects | Where-Object {$_.Name -eq $object.object -and $_.Schema -eq $object.schema} | measure-Object).count | Should -BeGreaterOrEqual 1 -Because "$($object.schema).$($object.object) should exist and be unique"
                }
                ForEach ($perm in $object.permissions){
                    It "$($perm.grantee) Should have $($perm.permission) on object $($object.schema).$($object.object) (Config)" {
                        ($permissions | Where-Object {$_.schemaowner -eq $object.schema -and $_.Securable -eq $object.object -and $_.grantee -eq $perm.grantee -and $_.permission -eq $perm.permission} | Measure-Object).count | Should -BeGreaterOrEqual 1 -Because "$($perm.grantee) should have $($perm.permission) on $($object.schema).$($object.object)"
                    }
                }
            }
        }

        Foreach ($object in $dbObjects){
            Describe "Checking $($object.schema).$($object.Name) (DB)"{
                It "Object $($object.schema).$($object.Name) Should be in Config (DB)"{
                    ($config.objects | Where-Object {$_.object -eq $object.Name} | Measure-Object).count | Should -BeGreaterOrEqual 1 
                }

                $cPerms = $config.objects | Where-Object {$_.schema -eq $object.schema -and $_.object -eq $object.name}
                ForEach ($perm in ($permissions | Where-Object {$object.name -eq $_.Securable -and $_.schemaowner -eq $object.schema})) {
                   It "Principal $($perm.Grantee) Should have $($perm.Permission) on object $($object.Schema).$($object.Name) (DB)" {
                       ($cPerms.Permissions | Where-Object {$_.Grantee -eq $perm.Grantee -and $_.Permission -eq $perm.Permission} | Measure-Object).count | Should -BeGreaterOrEqual 1
                   }
                }
            }
        }


        

        