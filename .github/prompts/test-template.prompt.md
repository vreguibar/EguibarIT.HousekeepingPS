# PowerShell Pester Test Template

Generate a Pester test file for a PowerShell function that follows our testing standards. This test will be part of [EguibarIT.HousekeepingPS] module

## Requirements

- Function to Test: {{functionName}}
- Test File Name: {{functionName}}.Tests.ps1

<!-- The following metadata will help Copilot better understand the purpose and usage of this template -->
<!-- Copilot:metadata
{
  "templateType": "pesterTest",
  "moduleContext": "EguibarIT.HousekeepingPS",
  "placeholders": [
    {
      "name": "functionName",
      "description": "The name of the PowerShell function being tested"
    }
  ]
}
Copilot:metadata -->

## Test Structure

Include the following test categories:

1. Parameter validation tests
2. Functionality tests with various input combinations
3. Error handling tests
4. Edge case tests
5. Pipeline input tests
6. ShouldProcess tests (if applicable)
7. Performance tests
8. Documentation validation tests

## Testing Standards

- Mock external dependencies (AD queries, file operations)
- Implement Before/After test blocks for state-changing tests
- Use descriptive Context and It blocks
- Provide meaningful assertion messages
- Test both success and failure paths
- Include tests for each parameter set
- Test validation attributes behavior
- Validate function documentation
- Measure performance against acceptable thresholds

## Sample Structure

```powershell
BeforeAll {
    # Module import and setup
    $ModuleName = 'EguibarIT.HousekeepingPS'
    $FunctionName = '{{functionName}}'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

    Import-Module -Name $PathToManifest -Force

    # Mock dependencies
    Mock -CommandName Get-ADObject -MockWith {
        [PSCustomObject]@{
            DistinguishedName = 'CN=Test,DC=contoso,DC=com'
            ObjectClass = 'user'
        }
    }
}

Describe "{{functionName}}" {
    Context "Parameter Validation" {
        BeforeAll {
            $Command = Get-Command -Name $FunctionName
        }

        It "Should have the correct parameter attributes" {
            $Command | Should -HaveParameter -ParameterName 'Identity' -Mandatory
            $Command.Parameters['Identity'].Attributes.ValueFromPipeline | Should -BeTrue
        }

        It "Should validate input parameters" {
            { {{functionName}} -Identity '' } | Should -Throw
            { {{functionName}} -Identity $null } | Should -Throw
        }

        It "Should accept pipeline input" {
            $testInput = [PSCustomObject]@{ Identity = 'CN=Test,DC=contoso,DC=com' }
            $testInput | {{functionName}} | Should -Not -BeNull
        }
    }

    Context "Function Documentation" {
        BeforeAll {
            $Help = Get-Help -Name $FunctionName -Full
        }

        It "Should have proper help documentation" {
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
            $Help.Examples.Count | Should -BeGreaterThan 0
        }
    }

    Context "Functionality" {
        It "Should perform expected action" {
            $result = {{functionName}} -Identity 'CN=Test,DC=contoso,DC=com'
            $result | Should -Not -BeNull
            # Add specific property checks based on function output
        }

        It "Should use ShouldProcess when required" {
            {{functionName}} -Identity 'CN=Test,DC=contoso,DC=com' -WhatIf
            Should -Invoke -CommandName Get-ADObject -Times 0
        }
    }

    Context "Error Handling" {
        It "Should handle AD object not found" {
            Mock -CommandName Get-ADObject -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
            }

            {{functionName}} -Identity 'CN=NonExistent,DC=contoso,DC=com' -ErrorAction SilentlyContinue
            Should -Invoke -CommandName Write-Warning
        }

        It "Should handle general errors appropriately" {
            Mock -CommandName Get-ADObject -MockWith {
                throw "General error"
            }

            { {{functionName}} -Identity 'CN=Test,DC=contoso,DC=com' } |
                Should -Throw
        }
    }

    Context "Performance" {
        It "Should complete within acceptable time" {
            $Threshold = 2
            $Measure = Measure-Command {
                {{functionName}} -Identity 'CN=Test,DC=contoso,DC=com'
            }

            $Measure.TotalSeconds | Should -BeLessThan $Threshold
        }
    }
}

AfterAll {
    Remove-Module -Name $ModuleName -Force
}
```

`````markdown
