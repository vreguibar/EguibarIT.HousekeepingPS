Describe 'Get-AdOrphanGPO' {
    BeforeAll {
        # Mock domain information
        $mockDomain = @{
            DNSRoot           = 'EguibarIT.local'
            DistinguishedName = 'DC=EguibarIT,DC=local'
        }

        # Mock GPO objects
        $mockGPOs = @(
            @{
                Name        = '{12345678-1234-1234-1234-123456789012}'
                DisplayName = 'Orphaned GPO 1'
                whenChanged = (Get-Date).AddDays(-30)
            },
            @{
                Name        = '{87654321-4321-4321-4321-210987654321}'
                DisplayName = 'Orphaned GPO 2'
                whenChanged = (Get-Date).AddDays(-60)
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        # Mock GPO management object
        $mockGPO = @{
            DisplayName = 'Orphaned GPO 1'
            Delete      = { }
        }

        Mock Import-Module { }
        Mock Get-ADDomain { [PSCustomObject]$mockDomain }
        Mock Get-ADObject { $mockGPOs }
        Mock Get-ChildItem { @() }
        Mock Test-Path { $false }
        Mock Get-GPO { [PSCustomObject]$mockGPO }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should support WhatIf' {
            $result = Get-AdOrphanGPO -RemoveOrphanGPOs -WhatIf
            Should -Not -Invoke Get-GPO
            $result.RemovedGPOs.Count | Should -Be 0
        }
    }

    Context 'Function execution' {
        It 'Should detect orphaned GPOs' {
            $result = Get-AdOrphanGPO
            $result.OrphanedGPOs.Count | Should -Be 2
            $result.Success | Should -Be $true
        }

        It 'Should remove orphaned GPOs when specified' {
            $result = Get-AdOrphanGPO -RemoveOrphanGPOs
            $result.RemovedGPOs.Count | Should -Be 2
            $result.Success | Should -Be $true
        }

        It 'Should handle GPO removal errors' {
            Mock Get-GPO { throw 'Access denied' }
            $result = Get-AdOrphanGPO -RemoveOrphanGPOs
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'Module requirements' {
        It 'Should require ActiveDirectory module' {
            Mock Import-Module { throw 'Module not found' } -ParameterFilter {
                $Name -eq 'ActiveDirectory'
            }
            { Get-AdOrphanGPO } | Should -Throw 'Required module not available'
        }
    }
}
