Describe 'Get-AdStaleComputer' {
    BeforeAll {
        # Mock dependencies
        Mock Import-MyModule { }

        $testDate = Get-Date
        $mockComputers = @(
            @{
                Name               = 'PC1'
                DistinguishedName  = 'CN=PC1,DC=EguibarIT,DC=local'
                LastLogonTimestamp = $testDate.AddDays(-100).ToFileTime()
                Created            = $testDate.AddDays(-200)
                Enabled            = $true
            },
            @{
                Name               = 'PC2'
                DistinguishedName  = 'CN=PC2,DC=EguibarIT,DC=local'
                LastLogonTimestamp = $testDate.AddDays(-10).ToFileTime()
                Created            = $testDate.AddDays(-100)
                Enabled            = $true
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        Mock Get-ADComputer { $mockComputers }
    }

    Context 'Parameter Validation' {
        It 'Should accept valid DaysOffset' {
            { Get-AdStaleComputer -DaysOffset 30 } | Should -Not -Throw
        }

        It 'Should reject invalid DaysOffset' {
            { Get-AdStaleComputer -DaysOffset 0 } | Should -Throw
            { Get-AdStaleComputer -DaysOffset 4000 } | Should -Throw
        }

        It 'Should accept valid SearchBase' {
            Mock Test-IsValidDN { $true }
            { Get-AdStaleComputer -SearchBase 'DC=EguibarIT,DC=local' } | Should -Not -Throw
        }

        It 'Should reject invalid SearchBase' {
            Mock Test-IsValidDN { $false }
            { Get-AdStaleComputer -SearchBase 'invalid' } | Should -Throw
        }
    }

    Context 'Function Execution' {
        It 'Should find stale computers' {
            $result = Get-AdStaleComputer -DaysOffset 50
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'PC1'
        }

        It 'Should respect DaysOffset parameter' {
            $result = Get-AdStaleComputer -DaysOffset 150
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }

        It 'Should handle no results' {
            Mock Get-ADComputer { @() }
            $result = Get-AdStaleComputer
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should handle AD query errors' {
            Mock Get-ADComputer { throw 'AD Error' }
            { Get-AdStaleComputer } | Should -Throw
        }
    }
}
