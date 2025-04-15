#Requires -Modules Pester

BeforeAll {
    # Import the function to test
    . "$PSScriptRoot\..\Private\Get-FunctionDisplay.ps1"

    # Create a global Constants object to simulate module constants
    # This is required for the function to work properly
    $global:Constants = @{
        NL   = [System.Environment]::NewLine
        HTab = "`t"  # Horizontal tab character
    }
}

Describe 'Get-FunctionDisplay' {
    Context 'Parameter validation' {
        It 'Should have a mandatory HashTable parameter' {
            (Get-Command Get-FunctionDisplay).Parameters['HashTable'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $true
        }

        It 'Should have an optional TabCount parameter' {
            (Get-Command Get-FunctionDisplay).Parameters['TabCount'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $false
        }

        It 'Should have TabCount default value of 2' {
            (Get-Command Get-FunctionDisplay).Parameters['TabCount'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.PSDefaultValueAttribute] } |
                Select-Object -ExpandProperty Value |
                Should -Be 2
        }
    }

    Context 'Function behavior' {
        BeforeAll {
            # Create test hashtables for testing
            $emptyHashtable = @{}
            $singleItemHashtable = @{ Key1 = 'Value1' }
            $multiItemHashtable = @{
                Key1 = 'Value1'
                Key2 = 'Value2'
                Key3 = 'Value3'
            }
        }

        It 'Should handle an empty hashtable' {
            $result = Get-FunctionDisplay -HashTable $emptyHashtable
            $result | Should -Match 'No PsBoundParameters to display.'
        }

        It 'Should return a string for a non-empty hashtable' {
            $result = Get-FunctionDisplay -HashTable $singleItemHashtable
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should include all keys from the input hashtable' {
            $result = Get-FunctionDisplay -HashTable $multiItemHashtable
            $multiItemHashtable.Keys | ForEach-Object {
                $result | Should -Match $_
            }
        }

        It 'Should include all values from the input hashtable' {
            $result = Get-FunctionDisplay -HashTable $multiItemHashtable
            $multiItemHashtable.Values | ForEach-Object {
                $result | Should -Match $_
            }
        }

        It 'Should apply the specified number of tabs' {
            # Test with 3 tabs
            $result = Get-FunctionDisplay -HashTable $singleItemHashtable -TabCount 3

            # Calculate expected tab count
            $expectedTabPattern = ($Constants.HTab * 3)

            # Check if the pattern exists in the result
            $result.Contains($expectedTabPattern) | Should -BeTrue
        }

        It 'Should use the default tab count when not specified' {
            $result = Get-FunctionDisplay -HashTable $singleItemHashtable

            # Calculate expected tab count (default is 2)
            $expectedTabPattern = ($Constants.HTab * 2)

            # Check if the pattern exists in the result
            $result.Contains($expectedTabPattern) | Should -BeTrue
        }
    }

    Context 'Pipeline support' {
        It 'Should accept pipeline input for HashTable parameter' {
            $testHashtable = @{ Key1 = 'Value1' }
            $result = $testHashtable | Get-FunctionDisplay
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Key1'
            $result | Should -Match 'Value1'
        }
    }

    Context 'Output format and structure' {
        It 'Should include newlines in the output' {
            $testHashtable = @{ Key1 = 'Value1' }
            $result = Get-FunctionDisplay -HashTable $testHashtable
            $result.Split($Constants.NL).Count | Should -BeGreaterThan 1
        }

        It 'Should start and end with newlines' {
            $testHashtable = @{ Key1 = 'Value1' }
            $result = Get-FunctionDisplay -HashTable $testHashtable
            $result | Should -Match "^$($Constants.NL)"
            $result | Should -Match "$($Constants.NL)$"
        }
    }

    Context 'Error handling' {
        It 'Should throw an appropriate error when HashTable parameter is null' {
            { Get-FunctionDisplay -HashTable $null } | Should -Throw
        }
    }
}
