# PowerShell Coding Style Guide

This document outlines the coding style and best practices for PowerShell functions in [EguibarIT.HousekeepingPS] module.

## Structure

- Public functions → Public folder
- Private/internal → Private folder
- Classes → Classes folder
- Enumerations → Enums folder
- Pester tests → Tests folder

## Naming Conventions

### Functions

- Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
- Use PowerShell functions with proper design patterns
- Use PascalCase for noun part of function names
- Example: `Get-ADUserPermission`, `Set-GroupPolicyRights`

### Variables

- Use PascalCase for all variables
- Always use strongly typed variables (e.g., `[string]$variableName`, `[int]$count`)
- Avoid abbreviations unless commonly understood

### Parameters

- Use PascalCase
- Choose descriptive names
- Mandatory attribute either with True if required or False if not
- Always include ValueFromPipeline/ValueFromPipelineByPropertyName/ValueFromRemainingArguments either if True or False
- HelpMessage for each parameter. Include short but understandable message.
- Position parameter specification
- Include appropriate validation attributes (e.g., `ValidateSet`, `ValidatePattern`, `ValidateLength`, `ValidateScript`, etc.)
- ParameterSetName when multiple parameter sets exist
- Type constraints

## Code Structure

### Function Layout

- Each function should include:
  - Comment-based help
  - CmdletBinding
  - OutputType declaration
  - Parameter block with proper attributes
  - Begin/Process/End blocks
  - Return consistent object structures when appropriate

### Comment-Based Help

- Synopsis
- Description
- Parameter descriptions
- Examples with realistic use cases and descriptions
- Inputs
- Outputs
- Notes section with:
  - Required modules/prerequisites
  - Table of cmdlets used and their modules. Lookup in the function which CMDlets/Functions are used and build the table with this information (e.g.,

  ```powershell
    Used Functions:
        Name                                       ║ Module/Namespace
        ═══════════════════════════════════════════╬══════════════════════════════
        Get-ADObject                               ║ ActiveDirectory
        Write-Verbose                              ║ Microsoft.PowerShell.Utility
        Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS
  ```

  )
  - Notes section with Version information, date and author. Update version if existing. Update date (e.g.,

  ```powershell
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        `vicente@eguibar.com`
                        Eguibar IT
                        `http://www.eguibarit.com`
  ```

  )
  - Link section with github repository and any other link related to the function
  - Component
  - Role
  - Functionality

### CmdletBinding

- Include [CmdletBinding()] with appropriate parameters (e.g., `SupportsShouldProcess`, `ConfirmImpact`, `DefaultParameterSetName`)
- Set SupportsShouldProcess to true when function makes changes
- Define DefaultParameterSetName when needed
- Specify OutputType indicating return type

### Parameter Block

- Mandatory attribute either with True if required or False if not
- Always include ValueFromPipeline/ValueFromPipelineByPropertyName/ValueFromRemainingArguments either if True or False
- HelpMessage for each parameter. Include short but understandable message.
- Position parameter specification
- When needed, define ParameterSetName when multiple parameter sets exist
- Include appropriate validation attributes (e.g., `ValidateSet`, `ValidatePattern`, `ValidateLength`, `ValidateScript`, etc.)
- Type constraints
- Include appropriate pipeline support

### Begin, Process and End blocks

- Always define Begin/Process/End blocks for efficiency.
- Block endings explicitly marked with corresponding `#end Begin`, `#end Process`, `#end End`, `#end Function <Function Name>`
- Use [PSCredential] and secure handling of credentials.
- Inline documentation inside each code block

#### Begin block

Begin block always include `Set-StrictMode -Version Latest`, display header, Module import section, Variables definition section. Example:

```powershell
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

        ##############################`
        # Module Import`


        ##############################`
        # Variables Definition`
```

#### Process Block

- Handle both pipeline input and batch processing efficiently
- Include appropriate progress indicators
- Implement ShouldProcess if functions makes changes

#### End Block

- Clean up resources as needed
- Return appropriate output objects
- End block always include any return or finalization message and default ending message. Example:

````powershell
    # Other return or finish messages

    # Display function footer if variables exist
    if ($null -ne $Variables -and
        $null -ne $Variables.FooterHousekeeping) {

        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'processing AdminCount & Permissions.'
        )
        Write-Verbose -Message $txt
    } #end If

    return $results
````

## Code Formatting

### Indentation & Line Length

- Use 4 spaces for indentation
- Limit lines to 120 characters
- Split long lines at logical points

### Braces & Whitespace

- Opening braces on same line between spaces
- Closing braces on a new line
- Spaces around operators
- Space after commas

### String Formatting

- Use single quotes for strings without variables
- Use format operator `-f` for string formatting (e.g., `'Found {0} objects' -f $Count`)

## Error Handling & Logging

### Error Handling

- Use try/catch blocks for error-prone operations
- Use specific catch blocks for different error types
- Catch specific exceptions when possible
- Provide meaningful error messages

### Verbose Output

- Always provide named parameter, and if message uses variable use string format within parenthesis
- Use `Write-Verbose -Message 'text'` for general progress information
- Use `Write-Debug -Message 'text'` for detailed output and troubleshooting
- Use `Write-Warning -Message 'text'` for non-terminal issues
- Use `Write-Error -Message 'text'` for terminal issues

## Security & Performance

### Security

- Never store credentials in plain text
- Use SecureString for sensitive data
- Validate and sanitize all input and output
- Avoid `Invoke-Expression` and inline credentials

### Performance

- Cache results when appropriate
- Use LDAP filters instead of client-side filtering
- Implement pagination for large result sets
- Prefer .NET methods over PowerShell cmdlets for performance-critical operations

## Testing

### Pester Tests

- Create test files with naming convention `[FunctionName].Tests.ps1` within the tests folder
- Test parameter validation scenarios (valid/invalid inputs)
- Test expected functionality with various input combinations
- Test error handling
- Edge cases specific to the function's purpose
- For functions that modify state, implement Before/After test blocks to verify changes
- Include test coverage for pipeline input scenarios
- Ensure tests run without requiring administrator privileges when possible
- Add tests for -WhatIf and -Confirm parameter functionality where ShouldProcess is implemented
- Consider including performance tests for functions that handle large datasets
- Mock external dependencies

## Documentation

### Function Documentation

- Document all parameters
- Include examples for common use cases
- Document return values
- Note any prerequisites or dependencies
- Document code blocks
- Include in-line documentation with clear comments
- Block endings explicitly marked (e.g., `#end If`, `#end If-Else`, `#end If-ElseIf-Else`, `#end Try-Catch`, `#end Try-Catch-Finally`, `#end ForEach`, `#end switch`, `#end Function Name`)
