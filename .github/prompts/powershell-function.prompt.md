# Task: Write a PowerShell function for an Active Directory environment

## Context

You are writing a function for [EguibarIT.HousekeepingPS] module in a Windows Server environment (2019-2025) using PowerShell 7+. The function must:

- Follow the Active Directory tiering model
- Follow the Active Directory delegation model
- Be secure, idempotent, and scalable (100k+ objects)
- Belong to a module following [EguibarIT.HousekeepingPS] folder structure
- Support ShouldProcess, comment-based help, Pester testing
- Security: Follow Active Directory tiering model and security best practices
- Scale: Optimized for large-scale AD/Windows environments (100,000+ objects)

## Implementation Requirements

- CmdletBinding, Begin/Process/End
- OutputType and parameter validation
- Constants section if needed
- Verbose, Debug, Warning, Error messages
- Secure credential handling using [PSCredential]
- Use AD module cmdlets, avoid hardcoding
- Include usage of Write-Progress in loops
- Include Pester test file: [FunctionName].Tests.ps1

## Function Structure Requirements

Comment-Based Help

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
        https://github.com/vreguibar/EguibarIT
    #>
```

CmdletBinding and Parameters

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

Block Structure

```powershell
    Begin {
        Set-StrictMode -Version Latest

        # Module imports
        Import-Module -Name ActiveDirectory -Force

        # Variables Definition
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
    } #end Begin

    Process {
        # Process logic here
        ForEach ($Item in $Identity) {
            Write-Progress -Activity 'Processing items' -Status ('Processing {0}' -f $Item) -PercentComplete (($i++ / $Identity.Count) * 100)

            try {
                # Main functionality
            } catch [System.Exception] {
                Write-Error -Message ('Error occurred: {0}' -f $_.Exception.Message)
            }
        } #end ForEach
    } #end Process

    End {
        # Clean up or final actions
        Write-Verbose -Message 'Completed processing all items'
    } #end End
```

## Performance Requirements

- Support batch processing of multiple objects simultaneously
- Optimize for large AD environments (100,000+ objects)
- Minimize redundant queries to AD (cache results when appropriate)
- Use efficient filtering methods (LDAP filters at source rather than client-side filtering)
- Consider using AD indexing for search operations
- Implement appropriate pagination for large result sets
- Follow the single-responsibility principle

## Security Requirements

- Never store credentials or sensitive data in plain text
- Use SecureString for password parameters
- Implement the least privilege principle
- Sanitize all user input before using it in queries
- Avoid using Invoke-Expression with user-supplied input
- Use credential parameters with proper validation
- Sanitize any output that might contain sensitive information

## Testing Requirements

- Include Pester test files with naming convention [FunctionName].Test.ps1
- Cover parameter validation, functionality, error handling, edge cases
- Mock external dependencies for independent testing
- Test pipeline input scenarios
- Test ShouldProcess functionality where implemented
