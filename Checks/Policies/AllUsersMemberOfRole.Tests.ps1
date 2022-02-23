<# 
Description: Ensures that all users are a member of a role 

Reason: Better control of user data access if only allowed via views or stored procedures
#>

param (
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

Describe "All users in the database should be a member of a role" {
    It "Should have 0 users without group memberships" {
        $sql = "select 
                    dp.principal_id, 
                    drm.role_principal_id 
                from 
                    sys.database_principals dp 
                        left outer join sys.database_role_members drm on dp.principal_id=drm.member_principal_id
                where 
                    dp.type='S' and 
                    dp.principal_id>5 and 
                    drm.member_principal_id is null"
        $results = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -Query $sql
        $results.count | Should -Be 0 -Because "Not assigning access direct to base tables allows more control"
    }
}
