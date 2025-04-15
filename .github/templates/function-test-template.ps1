BeforeAll {
    # Module import and setup
    $ModuleName = 'EguibarIT.HousekeepingPS'
    $FunctionName = 'FUNCTIONNAME'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

    Import-Module -Name $PathToManifest -Force

    # Define test variables
    $TestDN = 'CN=TestUser,OU=Users,DC=EguibarIT,DC=local'

    # Mock dependencies
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

Describe 'FUNCTIONNAME' {
    Context 'Parameter Validation' {
        BeforeAll {
            $Command = Get-Command -Name $FunctionName
        }

        It 'Should have the correct parameter attributes' {
            $Command | Should -HaveParameter -ParameterName 'Identity' -Mandatory
            $Command.Parameters['Identity'].Attributes.ValueFromPipeline | Should -BeTrue
            $Command.Parameters['Identity'].Attributes.ValueFromPipelineByPropertyName | Should -BeTrue
        }

        It 'Should validate input parameters' {
            { $FunctionName -Identity '' } | Should -Throw
            { $FunctionName -Identity $null } | Should -Throw
        }

        It 'Should accept pipeline input' {
            $testInput = [PSCustomObject]@{ Identity = $TestDN }
            { $testInput | & $FunctionName } | Should -Not -Throw
        }
    }

    Context 'Function Documentation' {
        BeforeAll {
            $Help = Get-Help -Name $FunctionName -Full
        }

        It 'Should have proper help documentation' {
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
            $Help.Examples.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Functionality' {
        It 'Should return the correct object when a valid identity is provided' {
            $Result = & $FunctionName -Identity $TestDN -PassThru
            $Result.Identity | Should -Be $TestDN
            $Result.Success | Should -Be $true
            $Result.Object | Should -Not -BeNullOrEmpty
        }

        It 'Should use ShouldProcess when required' {
            & $FunctionName -Identity $TestDN -WhatIf
            Should -Invoke -CommandName Get-ADObject -Times 0
        }
    }

    Context 'Error Handling' {
        It 'Should handle non-existent identities correctly' {
            $NonExistentDN = 'CN=NonExistent,OU=Users,DC=EguibarIT,DC=local'
            $Result = & $FunctionName -Identity $NonExistentDN -PassThru -ErrorAction SilentlyContinue
            $Result.Identity | Should -Be $NonExistentDN
            $Result.Success | Should -Be $false
            $Result.Error | Should -Be 'Identity not found'
        }

        It 'Should handle AD object not found' {
            Mock -CommandName Get-ADObject -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
            }

            & $FunctionName -Identity $TestDN -ErrorAction SilentlyContinue
            Should -Invoke -CommandName Write-Warning
        }

        It 'Should handle general errors appropriately' {
            Mock -CommandName Get-ADObject -MockWith {
                throw 'General error'
            }

            { & $FunctionName -Identity $TestDN } | Should -Throw
        }
    }

    Context 'Performance' {
        It 'Should complete within acceptable time' {
            $Threshold = 2
            $Measure = Measure-Command {
                & $FunctionName -Identity $TestDN
            }

            $Measure.TotalSeconds | Should -BeLessThan $Threshold
        }
    }

    Context 'Edge Cases' {
        It 'Should handle multiple objects correctly' {
            $Result = & $FunctionName -Identity @($TestDN, $TestDN) -PassThru
            # Depending on function implementation, check appropriate behavior
            # This example assumes it returns an array of results
            $Result.Count | Should -Be 2
        }
    }
}

AfterAll {
    Remove-Module -Name $ModuleName -Force
}
