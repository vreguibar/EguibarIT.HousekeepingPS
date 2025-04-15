# PowerShell Function Template

Generate a PowerShell function that follows our coding standards and best practices. This function will be part of [EguibarIT.HousekeepingPS] module.

## Context

This template is for developing functions in a Windows Server environment (2019-2025) using PowerShell 7+. Functions must:

- Follow the Active Directory tiering model and delegation model
- Be secure, idempotent, and scalable (100k+ objects)
- Support ShouldProcess, comment-based help, Pester testing
- Be optimized for large-scale AD/Windows environments (100,000+ objects)

## Function Requirements

- Function Name: {{functionName}}
- Purpose: {{purpose}}
- Target Environment: Active Directory/Windows Server 2019-2022-2025/PowerShell 7
- Required Modules: {{modules}}

## Function Structure

### Comment-Based Help

```powershell
<#
    .SYNOPSIS
        Brief description of function purpose.

    .DESCRIPTION
        Detailed description of function functionality.

    .PARAMETER ParameterName
        Description of parameter purpose, expected values, and behavior.

    .EXAMPLE
        Example-Function -Parameter1 'Value' -Parameter2 'Value'
        Description of what this example does.

    .EXAMPLE
        'Value' | Example-Function -Parameter2 'Value'
        Description of what this pipeline example does.

    .INPUTS
        [InputType] - Description of input object(s) that can be piped into the function.

    .OUTPUTS
        [OutputType] - Description of returned object(s).

    .NOTES
        Version:         1.0
        DateModified:    dd/MMM/yyyy
        LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com

        Used Functions:
            Name                             ║ Module/Namespace
            ═════════════════════════════════╬══════════════════════════════
            [Cmdlet name]                    ║ [Module/Namespace]

    .LINK
        https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/README.md#function-name

    .COMPONENT
        [Component] - Description of the component this function belongs to.

    .ROLE
        [Role] - Description of the role this function plays in the module.

    .FUNCTIONALITY
        [Functionality] - Description of the functionality this function provides.
#>
```

### CmdletBinding and Parameters

    - Use `CmdletBinding` with appropriate `SupportsShouldProcess` setting
    - Analyze and define the impact of the function (Low, Medium, High)
    - Include default parameter set name IF MORE THAN 1 IS USED.
    - OutputType declaration
    - Include Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage and Position attributes

```powershell
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'DefaultSet'
    )]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Parameter description'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('DN', 'DistinguishedName')]
        [String]$Identity,

        [Parameter(Mandatory = $false)]
        [Switch]$PassThru
    )
```

### Block Structure

```powershell
Begin {
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

    ##############################
    # Module imports
    Import-Module -Name ActiveDirectory -Force

    ##############################
    # Variables Definition

    [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
    [hashtable]$SplatProgress = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

} #end Begin

Process {
    # Process logic here
    ForEach ($Item in $Identity) {

         $SplatProgress = @{
            Activity        = 'Processing items'
            Status          = ('Processing {0}' -f $Item)
            PercentComplete = (($i++ / $Identity.Count) * 100)
        }
        Write-Progress @SplatProgress

        try {
            if ($PSCmdlet.ShouldProcess($Item, 'Operation description')) {
                # Main functionality
            }
        } catch [System.Exception] {
            Write-Error -Message ('Error occurred: {0}' -f $_.Exception.Message)
        }
    } #end ForEach
} #end Process

End {
    Write-Progress -Activity 'Processing objects' -Completed

    # Display function footer if variables exist
    if ($null -ne $Variables -and
        $null -ne $Variables.FooterHousekeeping) {

        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'processing XXXXX XXXXX & XXXXX.'
        )
        Write-Verbose -Message $txt
    } #end If
} #end End
```

## Coding Standards

1. **Naming Conventions**
   - Use PascalCase for all variables, functions, and parameters
   - Use approved PowerShell verbs
   - Use singular nouns for function names

2. **String Formatting**
   - Use single quotes for strings without variables
   - Use `-f` operator for string formatting: `'Text {0}' -f $Variable`

3. **Error Handling**
   - Use try/catch blocks with specific exception types when possible
   - Provide meaningful error messages
   - Use appropriate Write-* cmdlets based on severity

4. **Parameter Design**
   - Include proper validation attributes
   - Add HelpMessage for all parameters
   - Add Position for important parameters
   - Implement pipeline support where appropriate
   - Use parameter sets for complex functions

## Performance Requirements

- Support batch processing of multiple objects simultaneously
- Minimize redundant queries to AD (cache results when appropriate)
- Use efficient filtering with LDAP filters at source rather than client-side filtering
- Implement appropriate pagination for large result sets
- Follow the single-responsibility principle

## Security Requirements

- Never store credentials or sensitive data in plain text
- Use SecureString for password parameters
- Implement the least privilege principle
- Sanitize all user input before using it in queries
- Avoid using Invoke-Expression with user-supplied input
- Use credential parameters with proper validation

## Testing Requirements

- Include Pester test files with naming convention [FunctionName].Tests.ps1
- Cover parameter validation, functionality, error handling, edge cases
- Mock external dependencies for independent testing
- Test pipeline input scenarios
- Test ShouldProcess functionality where implemented

> For detailed testing guidance and a complete Pester test template, refer to the dedicated [test-template.prompt.md](./test-template.prompt.md) file.
