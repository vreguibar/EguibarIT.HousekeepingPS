#Requires -Modules Pester

BeforeAll {
    # Import the function to test
    . "$PSScriptRoot\..\Private\Get-FunctionDisplay.ps1"

    # Instead of trying to create a global variable, create a local mock
    # and use Mock to return the constants when needed
    $script:MockConstants = @{
        NL   = [System.Environment]::NewLine
        HTab = "`t"  # Horizontal tab character
    }

    # Mock the Constants variable access in the function
    Mock -CommandName Get-Variable -MockWith {
        return $script:MockConstants
    } -ParameterFilter { $Name -eq 'Constants' }

    # Create test hashtables for testing
    $script:emptyHashtable = @{}
    $script:singleItemHashtable = @{ Key1 = 'Value1' }
    $script:multiItemHashtable = @{
        Key1 = 'Value1'
        Key2 = 'Value2'
        Key3 = 'Value3'
    }
}

# Make sure this file uses Pester v5 syntax
Describe 'Get-FunctionDisplay' {
    Context 'Parameter validation' {
        It 'Should have a mandatory HashTable parameter' {
            $cmdlet = Get-Command -Name Get-FunctionDisplay
            $parameter = $cmdlet.Parameters['HashTable']
            $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory } | Should -BeTrue
        }

        It 'Should have an optional TabCount parameter' {
            $cmdlet = Get-Command -Name Get-FunctionDisplay
            $parameter = $cmdlet.Parameters['TabCount']
            $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory } | Should -BeFalse
        }

        It 'Should have TabCount default value of 2' {
            # Instead of checking the DefaultValue property directly, let's use a different approach
            # We'll invoke the function without specifying TabCount and check the resolved value

            # Get the function's AST (Abstract Syntax Tree)
            $functionDefinition = (Get-Command -Name Get-FunctionDisplay).ScriptBlock.Ast

            # Find the parameter with name 'TabCount'
            $tabCountParam = $functionDefinition.FindAll({
                    param($ast)
                    $ast -is [System.Management.Automation.Language.ParameterAst] -and
                    $ast.Name.VariablePath.UserPath -eq 'TabCount'
                }, $true) | Select-Object -First 1

            # Get the default value from the AST
            if ($tabCountParam) {
                $defaultValue = $tabCountParam.DefaultValue.Value
                $defaultValue | Should -Be 2
            } else {
                # Fallback to test the behavior
                # Create a minimal hashtable and check indentation in output
                $testHashtable = @{ Key = 'Value' }
                $result = Get-FunctionDisplay -HashTable $testHashtable

                # The default TabCount should be 2, so we expect 2 tabs in the output
                $expectedTabPattern = ($script:MockConstants.HTab * 2)
                $result.Contains($expectedTabPattern) | Should -BeTrue
            }
        }
    }

    Context 'Function behavior' {
        It 'Should handle an empty hashtable' {
            $result = Get-FunctionDisplay -HashTable $script:emptyHashtable
            # Update to match the actual message in the function
            $result | Should -Match 'Empty hashtable received, no parameters to display.'
        }

        It 'Should return a string for a non-empty hashtable' {
            $result = Get-FunctionDisplay -HashTable $script:singleItemHashtable
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should include all keys from the input hashtable' {
            $result = Get-FunctionDisplay -HashTable $script:multiItemHashtable
            foreach ($key in $script:multiItemHashtable.Keys) {
                $result | Should -Match $key
            }
        }

        It 'Should include all values from the input hashtable' {
            $result = Get-FunctionDisplay -HashTable $script:multiItemHashtable
            foreach ($value in $script:multiItemHashtable.Values) {
                $result | Should -Match $value
            }
        }

        It 'Should apply the specified number of tabs' {
            # Test with 3 tabs
            $result = Get-FunctionDisplay -HashTable $script:singleItemHashtable -TabCount 3

            # Calculate expected tab pattern
            $expectedTabPattern = ($script:MockConstants.HTab * 3)

            # Check if the pattern exists in the result
            $result.Contains($expectedTabPattern) | Should -BeTrue
        }

        It 'Should use the default tab count when not specified' {
            $result = Get-FunctionDisplay -HashTable $script:singleItemHashtable

            # Calculate expected tab count (default is 2)
            $expectedTabPattern = ($script:MockConstants.HTab * 2)

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
            ($result.Split($script:MockConstants.NL).Count) | Should -BeGreaterThan 1
        }

        It 'Should start and end with newlines' {
            $testHashtable = @{ Key1 = 'Value1' }
            $result = Get-FunctionDisplay -HashTable $testHashtable
            $result | Should -Match "^$([regex]::Escape($script:MockConstants.NL))"
            $result | Should -Match "$([regex]::Escape($script:MockConstants.NL))$"
        }
    }

    Context 'Error handling' {
        It 'Should throw an appropriate error when HashTable parameter is null' {
            { Get-FunctionDisplay -HashTable $null } | Should -Throw
        }
    }
}
