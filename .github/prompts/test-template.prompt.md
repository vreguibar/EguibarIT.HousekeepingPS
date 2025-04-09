# PowerShell Pester Test Template

Generate a Pester test file for a PowerShell function that follows our testing standards. This test will be part of [EguibarIT.HousekeepingPS] module

## Requirements

- Function to Test: {{functionName}}
- Test File Name: {{functionName}}.Tests.ps1

## Test Structure

Include the following test categories:

1. Parameter validation tests
2. Functionality tests with various input combinations
3. Error handling tests
4. Edge case tests
5. Pipeline input tests
6. ShouldProcess tests (if applicable)

## Testing Standards

- Mock external dependencies (AD queries, file operations)
- Implement Before/After test blocks for state-changing tests
- Use descriptive Context and It blocks
- Provide meaningful assertion messages
- Test both success and failure paths
- Include tests for each parameter set
- Test validation attributes behavior

## Sample Structure

```powershell
BeforeAll {
    # Import module and mock dependencies
    Import-Module -Name YourModule -Force

    # Mock dependencies
    Mock Get-ADObject { }
}

Describe "{{functionName}}" {
    Context "Parameter validation" {
        It "Should require mandatory parameters" {
            # Test code
        }

        It "Should validate parameter values" {
            # Test code
        }
    }

    Context "Functionality" {
        It "Should perform expected action with valid input" {
            # Test code
        }

        It "Should handle pipeline input" {
            # Test code
        }
    }

    Context "Error handling" {
        It "Should handle missing objects gracefully" {
            # Test code
        }

        It "Should catch and report specific errors" {
            # Test code
        }
    }
}
```
