Describe 'FUNCTIONNAME' {
    BeforeAll {
        # Import the module containing the function
        # Depending on your module structure, you might need to adjust this
        $ModulePath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-Module "$ModulePath\YourModuleName.psd1" -Force

        # Define test variables
        $TestDN = 'CN=TestUser,OU=Users,DC=EguibarIT,DC=local'

        # Mock Get-ADObject to avoid actual AD calls
        Mock -CommandName Get-ADObject -MockWith {
            # Return a mock object based on the parameters
            if ($Identity -eq $TestDN) {
                return [PSCustomObject]@{
                    DistinguishedName = $TestDN
                    ObjectClass       = 'user'
                    Name              = 'TestUser'
                    ObjectGUID        = [Guid]::NewGuid()
                }
            } else {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should throw when Identity is null or empty' {
            { FUNCTIONNAME -Identity $null } | Should -Throw
            { FUNCTIONNAME -Identity '' } | Should -Throw
        }

        It 'Should accept pipeline input' {
            { $TestDN | FUNCTIONNAME } | Should -Not -Throw
        }
    }

    Context 'Functionality' {
        It 'Should return the correct object when a valid identity is provided' {
            $Result = FUNCTIONNAME -Identity $TestDN -PassThru
            $Result.Identity | Should -Be $TestDN
            $Result.Success | Should -Be $true
            $Result.Object | Should -Not -BeNullOrEmpty
        }

        It 'Should handle non-existent identities correctly' {
            $NonExistentDN = 'CN=NonExistent,OU=Users,DC=EguibarIT,DC=local'
            $Result = FUNCTIONNAME -Identity $NonExistentDN -PassThru
            $Result.Identity | Should -Be $NonExistentDN
            $Result.Success | Should -Be $false
            $Result.Error | Should -Be 'Identity not found'
        }
    }

    Context 'ShouldProcess functionality' {
        It 'Should respect -WhatIf parameter' {
            FUNCTIONNAME -Identity $TestDN -WhatIf
            Should -Invoke -CommandName Get-ADObject -Times 0
        }
    }

    Context 'Error handling' {
        It 'Should handle and report errors correctly' {
