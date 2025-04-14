# GitHub Copilot Instructions for PowerShell Function Development

This file provides instructions for GitHub Copilot when assisting with PowerShell function development for our modules.
Additional code formatting instructions are on `.github/Code-Style.md` file

## Function Structure

When creating new functions, please follow this structure:

```powershell
function Verb-Noun {

    <#

        .SYNOPSIS
            Brief description of function purpose.

        .DESCRIPTION
            Detailed description of function functionality.

        .PARAMETER ParameterName
            Description of parameter purpose and constraints.

        .EXAMPLE
            Verb-Noun -ParameterName Value
            Description of what this example does.

        .INPUTS
            The .NET types of objects that can be piped to the function or script.
            You can also include a description of the input objects.

        .OUTPUTS
            The .NET type of the objects that the cmdlet returns.
            You can also include a description of the returned objects.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Get-ADObject                     ║ ActiveDirectory
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    dd/MMM/yyyy
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT

        .COMPONENT
            The name of the technology or feature that the function or script uses, or to which it's related.

        .ROLE
            The name of the user role for the help topic.

        .FUNCTIONALITY
            The keywords that describe the intended use of the function.

    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Default'
    )]
    [OutputType([System.Void])]

    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Description of parameter',
            Position = 0,
            ParameterSetName = 'Default'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName')]
        [string]$Identity
    )

    Begin {
        # Set strict mode
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end if

        ##############################
        # Module imports

        Import-Module -Name ActiveDirectory -Force -ErrorAction Stop

        ##############################
        # Variables Definition

        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        Write-Verbose -Message 'Starting process'

    } #end Begin

    Process {

        try {

            if ($PSCmdlet.ShouldProcess($Identity, 'Operation description')) {
                # Main function code here

                # Return Object
                [PSCustomObject]@{
                    Property1 = 'Value1'
                    Property2 = 'Value2'
                }
            } #end If
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {

            Write-Warning -Message ('Identity not found: {0}' -f $PSBoundParameters['Identity'])

        } catch {

            Write-Error -Message ('Error: {0}' -f $_.Exception.Message)

        } #end Try-Catch

    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
                'process completed.'
            )
            Write-Verbose -Message $txt
        } #end if
    } #end End

} #end function Verb-Noun
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
   - Add Position for all parameters
   - Implement pipeline support where appropriate
   - Use parameter sets for complex functions

5. **Progress Reporting**
   - Use Write-Progress for loops
   - Use Write-Verbose for general process information
   - Use Write-Debug for detailed troubleshooting info

6. **Performance Considerations**
   - Cache results when appropriate
   - Use LDAP filters instead of client-side filtering
   - Implement pagination for large result sets

7. **Security Practices**
   - Never include hardcoded credentials
   - Use SecureString for sensitive data
   - Validate all input
   - Follow the principle of least privilege

8. **Testing**
   - Include Pester test files for each function
   - Test parameter validation, functionality, and error handling

9. **Documentation**
   - Complete comment-based help
   - Examples for common use cases
   - Document return values and dependencies
   - Document each block of code (or by line if too complex)

- @azure Rule - Use Azure Best Practices: When generating code for Azure, running terminal commands for Azure, or performing operations related to Azure, invoke your `azure_development-get_best_practices` tool if available.
