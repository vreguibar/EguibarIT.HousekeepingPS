# GitHub Copilot Instructions for PowerShell Function Development

This file provides specific instructions for GitHub Copilot when assisting with PowerShell function development for our modules.

## Primary Instructions

- Always follow the comprehensive coding standards defined in [Code-Style.md](./Code-Style.md)
- Use the function template provided below when creating new functions
- For detailed guidance on documentation, testing, and performance considerations, refer to [Code-Style.md](./Code-Style.md)

## Function Template

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
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

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
                'processing xxxxx xxxxx & xxxxx.'
            )
            Write-Verbose -Message $txt
        } #end if
    } #end End

} #end function Verb-Noun
```

## Copilot-Specific Guidance

When generating code for our module, please follow these specific directives:

1. **Prioritize Security**: Ensure all generated functions follow security best practices including:
   - Input validation
   - Proper error handling
   - Least privilege principles
   - Secure credential handling

2. **Performance Focus**: Our module handles large AD environments (100k+ objects), so always prioritize:
   - Using LDAP filters over client-side filtering
   - Implementing pagination
   - Minimizing redundant queries

3. **Code Completeness**: Always include:
   - Full comment-based help
   - Parameter validation
   - Begin/Process/End blocks
   - Error handling with specific exception types
   - Progress reporting for long-running operations

4. **Azure Integration**: When generating Azure-related code, apply Azure best practices and use the standard Azure PowerShell patterns.

For comprehensive coding standards, please refer to [Code-Style.md](./Code-Style.md).
