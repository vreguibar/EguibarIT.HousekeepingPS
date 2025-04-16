#Requires -Modules Pester
#Requires -Version 5.0

BeforeAll {
    # Import the function to test - Fix path construction
    $ModuleRoot = Split-Path -Parent $PSScriptRoot

    # Since Test-NameIsWellKnownSid is a private function, we'll directly dot-source it
    $FunctionPath = Join-Path -Path $ModuleRoot -ChildPath 'Private\Test-NameIsWellKnownSid.ps1'

    # Verify the function file exists
    if (-not (Test-Path -Path $FunctionPath)) {
        throw "Function file not found at: $FunctionPath"
    }

    # Set up test variables for mocking
    $script:Variables = @{
        HeaderDelegation = '{0} - {1} - Parameters: {2}'
        FooterDelegation = 'End of {0} {1}'
        WellKnownSIDs    = @{
            'S-1-5-18'     = 'system'
            'S-1-5-19'     = 'localservice'
            'S-1-5-20'     = 'networkservice'
            'S-1-5-32-544' = 'administrators'
            'S-1-5-32-545' = 'users'
            'S-1-5-32-546' = 'guests'
            'S-1-1-0'      = 'everyone'
            'S-1-5-11'     = 'authenticated users'
            'S-1-5-32-555' = 'remote desktop users'
        }
    }

    # Mock Get-FunctionDisplay to avoid dependency
    function Get-FunctionDisplay {
        param ($HashTable, $Verbose)
        return ($HashTable | Out-String)
    }

    # Dot-source the function to test
    . $FunctionPath
}

Describe 'Test-NameIsWellKnownSid' {
    Context 'Parameter Validation' {
        It 'Should have a mandatory Name parameter' {
            $command = Get-Command -Name Test-NameIsWellKnownSid
            $parameter = $command.Parameters['Name']
            $parameter.Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory |
                Should -BeTrue
        }

        It 'Should throw when Name parameter is null or empty' {
            { Test-NameIsWellKnownSid -Name $null } | Should -Throw
            { Test-NameIsWellKnownSid -Name '' } | Should -Throw
        }
    }

    Context 'Function behavior with valid input' {
        It "Should return 'S-1-5-18' when passed 'SYSTEM'" {
            Test-NameIsWellKnownSid -Name 'SYSTEM' | Should -Be 'S-1-5-18'
        }

        It "Should return 'S-1-5-18' when passed 'NT AUTHORITY\SYSTEM'" {
            Test-NameIsWellKnownSid -Name 'NT AUTHORITY\SYSTEM' | Should -Be 'S-1-5-18'
        }

        It "Should return 'S-1-5-18' when passed 'system' (lowercase)" {
            Test-NameIsWellKnownSid -Name 'system' | Should -Be 'S-1-5-18'
        }

        It "Should return 'S-1-5-32-544' when passed 'Administrators'" {
            Test-NameIsWellKnownSid -Name 'Administrators' | Should -Be 'S-1-5-32-544'
        }

        It "Should return 'S-1-5-32-544' when passed 'BUILTIN\Administrators'" {
            Test-NameIsWellKnownSid -Name 'BUILTIN\Administrators' | Should -Be 'S-1-5-32-544'
        }

        It "Should return 'S-1-1-0' when passed 'Everyone'" {
            Test-NameIsWellKnownSid -Name 'Everyone' | Should -Be 'S-1-1-0'
        }

        It "Should return 'S-1-5-11' when passed 'Authenticated Users'" {
            Test-NameIsWellKnownSid -Name 'Authenticated Users' | Should -Be 'S-1-5-11'
        }
    }

    Context 'Function behavior with invalid input' {
        It 'Should return null for non-existent well-known SID names' {
            # Suppress expected errors for cleaner test output
            $ErrorActionPreference = 'SilentlyContinue'
            $result = Test-NameIsWellKnownSid -Name 'NonExistentName'
            $ErrorActionPreference = 'Continue'
            $result | Should -BeNullOrEmpty
        }

        It 'Should return null for partially matching names' {
            # Suppress expected errors for cleaner test output
            $ErrorActionPreference = 'SilentlyContinue'
            $result = Test-NameIsWellKnownSid -Name 'SystemAccount'
            $ErrorActionPreference = 'Continue'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Function behavior with different prefix formats' {
        It "Should handle 'NT AUTHORITY\' prefix" {
            Test-NameIsWellKnownSid -Name 'NT AUTHORITY\SYSTEM' | Should -Be 'S-1-5-18'
        }

        It "Should handle 'NTAUTHORITY\' prefix" {
            Test-NameIsWellKnownSid -Name 'NTAUTHORITY\SYSTEM' | Should -Be 'S-1-5-18'
        }

        It "Should handle 'BUILT-IN\' prefix" {
            Test-NameIsWellKnownSid -Name 'BUILT-IN\Administrators' | Should -Be 'S-1-5-32-544'
        }

        It "Should handle 'BUILTIN\' prefix" {
            Test-NameIsWellKnownSid -Name 'BUILTIN\Administrators' | Should -Be 'S-1-5-32-544'
        }
    }
}
