<#
    .SYNOPSIS
        Pester tests for Test-IsValidGUID function.

    .DESCRIPTION
        Contains tests to validate the Test-IsValidGUID function properly
        validates strings against the GUID format pattern.

    .NOTES
        Version:         1.1
        DateModified:    20/Mar/2024
        LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com
#>

BeforeAll {
    # Import the function we're testing
    . "$PSScriptRoot\..\Private\Test-IsValidGUID.ps1"

    # Ensure Constants variable exists for the function
    $Global:Constants = @{
        GuidRegEx = '^[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$'
    }

    # Verify function was imported
    $FunctionExists = Get-Command -Name Test-IsValidGUID -ErrorAction SilentlyContinue

    if (-not $FunctionExists) {
        throw 'Test-IsValidGUID function was not properly imported. Tests cannot continue.'
    }
}

Describe 'Test-IsValidGUID' {

    Context 'Parameter Validation' {
        # Use simpler approach to validate parameters
        It 'Should have parameter ObjectGUID as mandatory' {
            (Get-Help Test-IsValidGUID -Full).Parameters.Parameter |
                Where-Object { $_.Name -eq 'ObjectGUID' -and $_.Required -eq $true } |
                    Should -Not -BeNullOrEmpty
        }

        It 'Should have parameter ObjectGUID accepting pipeline input' {
            # Test pipeline support through execution rather than inspection
            '550e8400-e29b-41d4-a716-446655440000' | Test-IsValidGUID | Should -Be $true
        }

        It 'Should validate non-empty input' {
            { Test-IsValidGUID -ObjectGUID '' } | Should -Throw
        }
    }

    Context 'Valid GUID formats' {
        It 'Should return True for standard GUID format' {
            Test-IsValidGUID -ObjectGUID '550e8400-e29b-41d4-a716-446655440000' | Should -Be $true
        }

        It 'Should return True for uppercase GUID format' {
            Test-IsValidGUID -ObjectGUID '550E8400-E29B-41D4-A716-446655440000' | Should -Be $true
        }

        It 'Should return True for mixed case GUID format' {
            Test-IsValidGUID -ObjectGUID '550e8400-E29b-41D4-a716-446655440000' | Should -Be $true
        }

        It 'Should return True for GUID with braces' {
            Test-IsValidGUID -ObjectGUID '{550e8400-e29b-41d4-a716-446655440000}' | Should -Be $true
        }
    }

    Context 'Invalid GUID formats' {
        It 'Should throw validation error for empty string' {
            # Test that an exception is thrown for empty string
            { Test-IsValidGUID -ObjectGUID '' } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw validation error for null value' {
            # Test that an exception is thrown for null value
            { Test-IsValidGUID -ObjectGUID $null } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should return False for non-GUID format' {
            Test-IsValidGUID -ObjectGUID 'not-a-guid' | Should -Be $false
        }

        It 'Should return False for incorrectly formatted GUID (missing dashes)' {
            Test-IsValidGUID -ObjectGUID '550e8400e29b41d4a716446655440000' | Should -Be $false
        }

        It 'Should return False for incorrectly formatted GUID (wrong length)' {
            Test-IsValidGUID -ObjectGUID '550e8400-e29b-41d4-a716-4466554400' | Should -Be $false
        }

        It 'Should return False for incorrectly formatted GUID (non-hex characters)' {
            Test-IsValidGUID -ObjectGUID '550e8400-e29b-41d4-a716-44665544000g' | Should -Be $false
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input and return True for valid GUID' {
            '550e8400-e29b-41d4-a716-446655440000' | Test-IsValidGUID | Should -Be $true
        }

        It 'Should accept pipeline input and return False for invalid GUID' {
            'invalid-guid' | Test-IsValidGUID | Should -Be $false
        }
    }

    Context 'Error handling' {
        It 'Should not throw an exception when testing invalid input' {
            { Test-IsValidGUID -ObjectGUID 'not-a-guid' } | Should -Not -Throw
        }
    }
}

AfterAll {
    # Clean up
    Remove-Variable -Name Constants -Scope Global -ErrorAction SilentlyContinue
}
