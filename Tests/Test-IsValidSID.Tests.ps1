BeforeAll {
    # Import the function to test
    . "$PSScriptRoot\..\Private\Test-IsValidSID.ps1"

    # Mock global variables used by the function
    $global:Variables = @{
        WellKnownSIDs = @{
            'S-1-5-18'     = 'Local System'
            'S-1-5-19'     = 'Local Service'
            'S-1-5-20'     = 'Network Service'
            'S-1-5-32-544' = 'Administrators'
            'S-1-5-32-545' = 'Users'
            'S-1-1-0'      = 'Everyone'
        }
    }

    $global:Constants = @{
        SidRegEx = '^S-\d-(\d+-){1,14}\d+$'
    }
}

Describe 'Test-IsValidSID' {
    Context 'Parameter validation' {
        It 'Should have a mandatory ObjectSID parameter' {
            (Get-Command -Name Test-IsValidSID).Parameters['ObjectSID'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should throw when ObjectSID is null or empty' {
            { Test-IsValidSID -ObjectSID $null } | Should -Throw
            { Test-IsValidSID -ObjectSID '' } | Should -Throw
        }
    }

    Context 'Well-known SIDs' {
        It 'Should return true for the Local System SID' {
            Test-IsValidSID -ObjectSID 'S-1-5-18' | Should -BeTrue
        }

        It 'Should return true for the Administrators SID' {
            Test-IsValidSID -ObjectSID 'S-1-5-32-544' | Should -BeTrue
        }

        It 'Should return true for the Everyone SID' {
            Test-IsValidSID -ObjectSID 'S-1-1-0' | Should -BeTrue
        }

        It 'Should accept input from pipeline for well-known SIDs' {
            'S-1-5-19' | Test-IsValidSID | Should -BeTrue
        }
    }

    Context 'Valid SID format' {
        It 'Should return true for valid domain SID format' {
            Test-IsValidSID -ObjectSID 'S-1-5-21-2562450185-1914323539-512974444-1234' | Should -BeTrue
        }

        It 'Should handle SIDs with variable component counts' {
            Test-IsValidSID -ObjectSID 'S-1-5-21-123456789-123456789-123456789-1234' | Should -BeTrue
            Test-IsValidSID -ObjectSID 'S-1-5-21-123-456-789-1234' | Should -BeTrue
        }
    }

    Context 'Invalid SID format' {
        It 'Should return false for incorrectly formatted SIDs' {
            Test-IsValidSID -ObjectSID 'Not-A-SID' | Should -BeFalse
            Test-IsValidSID -ObjectSID 'S-1-' | Should -BeFalse
            Test-IsValidSID -ObjectSID 'S-1-X-32-544' | Should -BeFalse
            Test-IsValidSID -ObjectSID 'S11532544' | Should -BeFalse
        }
    }

    Context 'Domain\User format handling' {
        It 'Should handle domain\user format and extract the SID part' {
            # This test assumes the function extracts after \ character
            # and the extracted part is a valid SID
            Mock Get-Variable -ParameterFilter { $Name -eq 'Variables' } -MockWith {
                @{
                    WellKnownSIDs = @{ 'S-1-5-18' = 'Local System' }
                }
            }

            Test-IsValidSID -ObjectSID 'DOMAIN\S-1-5-18' | Should -BeTrue
        }
    }

    Context 'Verbose output' {
        It 'Should provide verbose output for valid well-known SID' {
            $verboseOutput = Test-IsValidSID -ObjectSID 'S-1-5-18' -Verbose 4>&1
            $verboseOutput | Should -Contain 'The SID S-1-5-18 is a WellKnownSid.'
        }

        It 'Should provide verbose output for valid regex SID' {
            $verboseOutput = Test-IsValidSID -ObjectSID 'S-1-5-21-2562450185-1914323539-512974444-1234' -Verbose 4>&1
            $verboseOutput | Should -Contain 'The SID S-1-5-21-2562450185-1914323539-512974444-1234 is valid.'
        }

        It 'Should provide verbose output for invalid SID' {
            $verboseOutput = Test-IsValidSID -ObjectSID 'Not-A-SID' -Verbose 4>&1
            # Use a more lenient approach to check for the message content
            $verboseOutput | Where-Object { $_ -match 'NOT valid' -and $_ -match 'Not-A-SID' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'WhatIf parameter' {
        It 'Should not perform validation when -WhatIf is specified' {
            $result = Test-IsValidSID -ObjectSID 'S-1-5-18' -WhatIf
            $result | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    # Clean up global variables
    Remove-Variable -Name Variables -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name Constants -Scope Global -ErrorAction SilentlyContinue
}
