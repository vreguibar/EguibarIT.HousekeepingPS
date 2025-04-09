# PowerShell Code Style Guide

This document outlines the coding style and best practices for PowerShell functions in [EguibarIT.HousekeepingPS] module.

## Structure

- Public functions → Public folder
- Private/internal → Private folder
- Classes → Classes folder
- Enumerations → Enums folder
- Pester tests → Tests folder

## General Guidelines

- Use PowerShell functions with proper design patterns
- Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
- Follow PascalCase naming convention for variables and functions
- Always use strongly typed variables (e.g., [string]$variableName, [int]$count)
- Avoid abbreviations unless commonly understood
- Maximum line length: 120 characters
- Use single quotes for strings unless string interpolation is needed
- Use string formatting rather than embedding variables ('Found {0} objects' -f $Count)
- Always include the Begin/Process/End blocks in functions

## Naming

- Functions: PascalCase, Verb-Noun (e.g., Get-DelegationTemplate)
- Variables: PascalCase (e.g., $DomainController)
- Constants: UpperCamelCase with prefix if needed (e.g., $EguibarConstantMaxLimit)

## CmdletBinding

- Include [CmdletBinding()] with appropriate parameters (e.g., `SupportsShouldProcess`, `ConfirmImpact`, `DefaultParameterSetName`)
- Set SupportsShouldProcess to true when function makes changes
- Define DefaultParameterSetName when needed
- Specify OutputType indicating return type

## Parameters

Parameters must include:

- Choose descriptive names
- Use PascalCase
- Mandatory attribute either with True if required or False if not
- ValueFromPipeline/ValueFromPipelineByPropertyName/ValueFromRemainingArguments as needed
- HelpMessage for each parameter
- Position parameter specification
- ParameterSetName when multiple parameter sets exist
- Proper parameter validation. Always validate input (e.g., `ValidateSet`, `ValidatePattern`, `ValidateLength`, `ValidateScript`)
- Type constraints

## Syntax & Semantics

- Always define Begin/Process/End blocks for efficiency. Block endings explicitly marked with corresponding `#end Begin`, `#end Process`, `#end End`
- Begin block always include `Set-StrictMode -Version Latest`, display header, Module import section, Variables definition section (e.g.,
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        `##############################`
        `# Module Import`


        `##############################`
        `# Variables Definition`

)

- Process Block
  - Handle both pipeline input and batch processing efficiently
  - Include appropriate progress indicators
- End Block
  - Clean up resources as needed
  - Return appropriate output objects
- Use [PSCredential] and secure handling of credentials.
- Inline documentation inside each code block.
- Return consistent object structures.
- Max line length: 120 characters.

## Indentation & Line Length

- Use 4 spaces for indentation
- Limit lines to 120 characters
- Split long lines at logical points

## Braces & Whitespace

- Opening braces on a new line
- Closing braces on a new line
- Spaces around operators
- Space after commas

## String Formatting

- Use single quotes for strings without variables
- Use format operator -f for string formatting. Example: 'Found {0} objects' -f $Count

## Error Handling

- Implement try/catch blocks for operations that may fail
- Use specific catch blocks for different error types
- Catch specific exceptions when possible
- Provide meaningful error messages
- Use appropriate error reporting cmdlets. Always provide named parameter, and if message uses variable, then string format:
  - Write-Verbose -Message 'text' for general information
  - Write-Debug -Message 'text'for detailed steps
  - Write-Warning -Message 'text'for non-terminating issues
  - Write-Error -Message 'text'for more serious problems

## Best Practices

- Cache AD queries
- Use Write-Progress in loops
- Prefer LDAP filters
- Avoid `Invoke-Expression` and inline credentials

## Comments and Comment-Based Help

- Include in-line documentation with clear comments
- Document prerequisites or dependencies
- Include examples of how to call/implement the function
- Inline comments start with #, 2 spaces after #
- Block endings explicitly marked: `#end If`, `#end If-Else`, `#end If-ElseIf-Else`, `#end Try-Catch`, `#end Try-Catch-Finally`, `#end ForEach`, `#end switch`, `#end Function Name`
- Every function must include:
  - Synopsis
  - Description
  - Parameter descriptions
  - Examples with realistic use cases
  - Outputs section
- Notes section with:
  - Required modules/prerequisites
  - Table of cmdlets used and their modules (e.g.,
  Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-ADObject                               ║ ActiveDirectory
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS
  )
  - Version information, date and author (e.g.,
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        `vicente@eguibar.com`
                        Eguibar IT
                        `http://www.eguibarit.com`
  )
  - Link section with github repository and any other link related to the function

## Testing

- Create Pester test files for each function with naming convention [FunctionName].Test.ps1
- Tests should cover:
  - Parameter validation scenarios (valid/invalid inputs)
  - Expected functionality with various input combinations
  - Error handling paths
  - Edge cases specific to the function's purpose
- For functions that modify state, implement Before/After test blocks to verify changes
- Include test coverage for pipeline input scenarios
- Ensure tests run without requiring administrator privileges when possible
- Add tests for -WhatIf and -Confirm parameter functionality where ShouldProcess is implemented
- Consider including performance tests for functions that handle large datasets

## Documentation

- Document all parameters
- Include examples for common use cases
- Document return values
- Note any prerequisites or dependencies
- Document code blocks
