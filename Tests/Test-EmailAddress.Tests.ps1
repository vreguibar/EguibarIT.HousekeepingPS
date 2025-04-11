Describe 'Test-EmailAddress' {
    BeforeAll {
        . $PSScriptRoot/../Private/Test-EmailAddress.ps1
    }

    Context 'Parameter validation' {
        It 'Should have mandatory EmailAddress parameter' {
            (Get-Command Test-EmailAddress).Parameters['EmailAddress'].Attributes.Mandatory |
                Should -Be $true
        }
    }

    Context 'Validation tests' {
        It 'Should return True for valid email' {
            Test-EmailAddress -EmailAddress 'test@domain.com' | Should -Be $true
        }

        It 'Should return False for invalid email' {
            Test-EmailAddress -EmailAddress 'invalid.email' | Should -Be $false
        }

        It 'Should handle pipeline input' {
            'test@domain.com' | Test-EmailAddress | Should -Be $true
        }

        It 'Should reject empty string' {
            { Test-EmailAddress -EmailAddress '' } | Should -Throw
        }
    }
}
