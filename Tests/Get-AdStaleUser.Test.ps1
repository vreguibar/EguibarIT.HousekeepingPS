Describe 'Get-AdStaleUser' {
    BeforeAll {
        # Mock dependencies
        Mock Import-MyModule { }

        $testDate = Get-Date
        $mockUsers = @(
            @{
                Name               = 'User1'
                SamAccountName     = 'user1'
                DistinguishedName  = 'CN=User1,DC=EguibarIT,DC=local'
                LastLogon          = $testDate.AddDays(-100).ToFileTime()
                LastLogonTimestamp = $testDate.AddDays(-100).ToFileTime()
                Created            = $testDate.AddDays(-200)
                Enabled            = $true
            },
            @{
                Name               = 'User2'
                SamAccountName     = 'user2'
                DistinguishedName  = 'CN=User2,DC=EguibarIT,DC=local'
                LastLogon          = $testDate.AddDays(-10).ToFileTime()
                LastLogonTimestamp = $testDate.AddDays(-10).ToFileTime()
                Created            = $testDate.AddDays(-100)
                Enabled            = $true
            }
        ) | ForEach-Object {
            $obj = [PSCustomObject]$_
            $obj.PSObject.TypeNames.Insert(0, 'Microsoft.ActiveDirectory.Management.ADUser')
            $obj
        }

        Mock Get-ADUser { $mockUsers }
        Mock Test-IsValidDN { $true }
    }

    Context 'Parameter Validation' {
        It 'Should accept valid DaysOffset' {
            { Get-AdStaleUser -DaysOffset 30 } | Should -Not -Throw
        }

        It 'Should reject invalid DaysOffset' {
            { Get-AdStaleUser -DaysOffset 0 } | Should -Throw
            { Get-AdStaleUser -DaysOffset 4000 } | Should -Throw
        }

        It 'Should accept valid SearchBase' {
            { Get-AdStaleUser -SearchBase 'DC=EguibarIT,DC=local' } | Should -Not -Throw
        }

        It 'Should accept valid credentials' {
            $cred = New-Object System.Management.Automation.PSCredential ('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-AdStaleUser -Credential $cred } | Should -Not -Throw
        }
    }

    Context 'Function Execution' {
        It 'Should find stale users' {
            $result = Get-AdStaleUser -DaysOffset 50
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].SamAccountName | Should -Be 'user1'
        }

        It 'Should respect DaysOffset parameter' {
            $result = Get-AdStaleUser -DaysOffset 150
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }

        It 'Should calculate DaysInactive correctly' {
            $result = Get-AdStaleUser -DaysOffset 50
            $result[0].DaysInactive | Should -BeGreaterThan 90
        }
    }

    Context 'Error Handling' {
        It 'Should handle AD query errors' {
            Mock Get-ADUser { throw 'AD Error' }
            { Get-AdStaleUser } | Should -Throw
        }

        It 'Should handle empty results' {
            Mock Get-ADUser { @() }
            $result = Get-AdStaleUser
            $result | Should -BeNullOrEmpty
        }
    }
}
