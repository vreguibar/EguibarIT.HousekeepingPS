Describe 'Get-AdOrphanGPT' {
    BeforeAll {
        # Mock dependencies
        Mock Get-ADDomain {
            @{
                DNSRoot           = 'EguibarIT.local'
                DistinguishedName = 'DC=EguibarIT,DC=local'
            }
        }

        Mock Test-Path { $true }

        Mock Get-ChildItem {
            @(
                @{
                    Name          = 'TestGPT1'
                    FullName      = '\\EguibarIT.local\SYSVOL\EguibarIT.local\Policies\TestGPT1'
                    LastWriteTime = (Get-Date).AddDays(-30)
                },
                @{
                    Name     = 'PolicyDefinitions'
                    FullName = '\\EguibarIT.local\SYSVOL\EguibarIT.local\Policies\PolicyDefinitions'
                }
            )
        }
    }

    Context 'Parameter Validation' {
        It 'Should accept valid domain controller' {
            { Get-AdOrphanGPT -DomainController 'dc1.EguibarIT.local' } | Should -Not -Throw
        }

        It 'Should accept valid credentials' {
            $cred = New-Object System.Management.Automation.PSCredential ('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-AdOrphanGPT -Credential $cred } | Should -Not -Throw
        }
    }

    Context 'Function Execution' {
        It 'Should find orphaned GPTs' {
            $result = Get-AdOrphanGPT
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Should respect BatchSize parameter' {
            $result = Get-AdOrphanGPT -BatchSize 500
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should handle inaccessible SYSVOL' {
            Mock Test-Path { $false }
            { Get-AdOrphanGPT } | Should -Throw
        }
    }
}
