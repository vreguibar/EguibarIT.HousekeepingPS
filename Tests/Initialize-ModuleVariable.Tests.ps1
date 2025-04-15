Describe 'Initialize-ModuleVariable' {
    BeforeAll {
        # Import required modules and dependencies
        $ModulePath = Split-Path -Path $PSScriptRoot -Parent
        $PrivatePath = Join-Path -Path $ModulePath -ChildPath 'Private'
        $FunctionPath = Join-Path -Path $PrivatePath -ChildPath 'Initialize-ModuleVariable.ps1'

        # We need to ensure the Variables hashtable exists before running tests
        $Global:Variables = @{}

        # Handle Constants variable - check if it exists globally first
        if (-not (Get-Variable -Name 'Constants' -Scope 'Global' -ErrorAction SilentlyContinue)) {
            $Global:Constants = @{
                guidNull = '00000000-0000-0000-0000-000000000000'
            }
        }

        # For testing purposes, ensure we can access the null GUID even if Constants is read-only
        $Script:TestGuidNull = '00000000-0000-0000-0000-000000000000'

        # Mock ActiveDirectory module if needed
        if (-not (Get-Module -Name 'ActiveDirectory' -ErrorAction SilentlyContinue)) {
            # Create a minimal mock of ActiveDirectory module for testing
            $ModuleDefinition = @'
                Function Get-ADObject {
                    param($SearchBase, $LDAPFilter, $Properties)
                    if ($LDAPFilter -eq '(schemaidguid=*)') {
                        @(
                            [PSCustomObject]@{
                                lDAPDisplayName = 'user'
                                schemaIDGUID = [byte[]](1..16)
                            },
                            [PSCustomObject]@{
                                lDAPDisplayName = 'group'
                                schemaIDGUID = [byte[]](17..32)
                            }
                        )
                    } elseif ($LDAPFilter -eq '(objectclass=controlAccessRight)') {
                        @(
                            [PSCustomObject]@{
                                displayName = 'User-Force-Change-Password'
                                rightsGuid = [byte[]](33..48)
                            },
                            [PSCustomObject]@{
                                displayName = 'DS-Replication-Manage-Topology'
                                rightsGuid = [byte[]](49..64)
                            }
                        )
                    }
                }
'@
            New-Module -Name 'ActiveDirectory' -Scriptblock ([ScriptBlock]::Create($ModuleDefinition)) | Import-Module
        }

        # Create a mock directory entry object instead of using Add-Type
        function New-MockDirectoryEntry {
            [PSCustomObject]@{
                DefaultNamingContext       = 'DC=eguibarit,DC=com'
                configurationNamingContext = 'CN=Configuration,DC=eguibarit,DC=com'
                namingContexts             = @('DC=eguibarit,DC=com', 'CN=Configuration,DC=eguibarit,DC=com')
                rootDomainNamingContext    = 'DC=eguibarit,DC=com'
                SchemaNamingContext        = 'CN=Schema,CN=Configuration,DC=eguibarit,DC=com'

                # Add ToString method to handle method calls
                ToString                   = {
                    return 'DC=eguibarit,DC=com'
                }
            } | Add-Member -MemberType ScriptMethod -Name ToString -Value { return 'DC=eguibarit,DC=com' } -Force -PassThru
        }

        # Mock ADSI calls by replacing the code in the function
        $FunctionContent = Get-Content -Path $FunctionPath -Raw

        # Replace ADSI calls with our mock function
        $ModifiedContent = $FunctionContent -replace '\[ADSI\]''LDAP://RootDSE''', 'New-MockDirectoryEntry'

        # Replace the guidNull reference
        $ModifiedContent = $ModifiedContent -replace '\$Constants\.guidNull', '($Constants.guidNull ?? $Script:TestGuidNull)'

        # Replace Domain.GetCurrentDomain calls
        $ModifiedContent = $ModifiedContent -replace '\[System\.DirectoryServices\.ActiveDirectory\.Domain\]::GetCurrentDomain\(\)\.Name', "'eguibarit.com'"

        # Mock New-Object for LDAP calls
        Mock -CommandName New-Object -ParameterFilter {
            $TypeName -eq 'System.DirectoryServices.DirectoryEntry' -and
            $ArgumentList -eq 'LDAP://RootDSE'
        } -MockWith {
            New-MockDirectoryEntry
        }

        # Load the modified function
        $ScriptBlock = [ScriptBlock]::Create($ModifiedContent)
        . $ScriptBlock
    }

    AfterAll {
        # Clean up
        Remove-Module -Name 'ActiveDirectory' -Force -ErrorAction SilentlyContinue

        # Remove our temporary variable
        Remove-Variable -Name TestGuidNull -Scope Script -ErrorAction SilentlyContinue

        # Make sure we don't affect the global Variables hashtable beyond our tests
        Remove-Variable -Name Variables -Scope Global -ErrorAction SilentlyContinue
    }

    Context 'Function Existence' {
        It 'Should exist' {
            $Function = Get-Command -Name 'Initialize-ModuleVariable' -ErrorAction SilentlyContinue
            $Function | Should -Not -BeNullOrEmpty
        }

        It 'Should be a function' {
            $Function = Get-Command -Name 'Initialize-ModuleVariable' -ErrorAction SilentlyContinue
            $Function.CommandType | Should -Be 'Function'
        }
    }

    Context 'Function execution and variable initialization' {
        BeforeEach {
            # Reset Variables hashtable before each test
            $Global:Variables = @{}
        }

        It 'Should initialize Active Directory context variables' {
            # Execute the function
            Initialize-ModuleVariable

            # Test if the variables are initialized properly
            $Variables.AdDN | Should -Be 'DC=eguibarit,DC=com'
            $Variables.configurationNamingContext | Should -Be 'CN=Configuration,DC=eguibarit,DC=com'
            $Variables.defaultNamingContext | Should -Be 'DC=eguibarit,DC=com'
            $Variables.DnsFqdn | Should -Be 'eguibarit.com'
            $Variables.namingContexts.Count | Should -BeGreaterThan 0
            $Variables.PartitionsContainer | Should -Be 'CN=Configuration,DC=eguibarit,DC=com'
            $Variables.rootDomainNamingContext | Should -Be 'DC=eguibarit,DC=com'
            $Variables.SchemaNamingContext | Should -Be 'CN=Schema,CN=Configuration,DC=eguibarit,DC=com'
        }

        It 'Should create GUID mappings for schema objects' {
            # Execute the function
            Initialize-ModuleVariable

            # Test if the GUID maps are created
            $Variables.GuidMap | Should -Not -BeNullOrEmpty
            $Variables.GuidMap.Keys.Count | Should -BeGreaterThan 0
            $Variables.GuidMap['All'] | Should -Be ($Constants.guidNull ?? $Script:TestGuidNull)
            $Variables.GuidMap['user'] | Should -Not -BeNullOrEmpty
            $Variables.GuidMap['group'] | Should -Not -BeNullOrEmpty
        }

        It 'Should create GUID mappings for extended rights' {
            # Execute the function
            Initialize-ModuleVariable

            # Test if the extended rights map is created
            $Variables.ExtendedRightsMap | Should -Not -BeNullOrEmpty
            $Variables.ExtendedRightsMap.Keys.Count | Should -BeGreaterThan 0
            $Variables.ExtendedRightsMap['All'] | Should -Be ($Constants.guidNull ?? $Script:TestGuidNull)
            $Variables.ExtendedRightsMap['User-Force-Change-Password'] | Should -Not -BeNullOrEmpty
            $Variables.ExtendedRightsMap['DS-Replication-Manage-Topology'] | Should -Not -BeNullOrEmpty
        }

        It 'Should handle errors gracefully when Get-ADObject fails for schema' {
            # Mock Get-ADObject to throw an error
            Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(schemaidguid=*)' } -MockWith {
                throw 'AD operation failed'
            }

            # Execute function and verify it throws an error
            { Initialize-ModuleVariable } | Should -Throw

            # The function should reach this point only if the error was caught
            # Verify GuidMap was not created (error occurred before it could be created)
            $Global:Variables.Keys -contains 'GuidMap' | Should -Be $false
        }

        It 'Should handle errors gracefully when Get-ADObject fails for extended rights' {
            # Mock Get-ADObject for schema to succeed but fail for extended rights
            Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(schemaidguid=*)' } -MockWith {
                @(
                    [PSCustomObject]@{
                        lDAPDisplayName = 'user'
                        schemaIDGUID    = [byte[]](1..16)
                    }
                )
            }

            Mock -CommandName Get-ADObject -ParameterFilter { $LDAPFilter -eq '(objectclass=controlAccessRight)' } -MockWith {
                throw 'AD operation failed'
            }

            # Execute function and verify it throws an error
            { Initialize-ModuleVariable } | Should -Throw

            # The function should have populated GuidMap but not ExtendedRightsMap
            $Global:Variables.Keys -contains 'GuidMap' | Should -Be $true
            $Global:Variables.GuidMap | Should -Not -BeNullOrEmpty

            # This should fail if ExtendedRightsMap was created successfully, which would indicate
            # the error wasn't handled correctly
            $Global:Variables.Keys -contains 'ExtendedRightsMap' | Should -Be $false
        }
    }
}
