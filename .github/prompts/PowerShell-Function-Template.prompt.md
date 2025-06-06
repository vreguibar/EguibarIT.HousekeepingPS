---
mode: 'agent'
tools: ['githubRepo', 'codebase', 'PSScriptAnalyzer', 'Pester', 'PlatyPS']
description: 'PowerShell Function Template'
---

# PowerShell Function Template Prompt

Generate a PowerShell function that follows our coding standards and best practices for the `EguibarIT.HousekeepingPS` module.

## Table of Contents

1. Context
2. Function Requirements
3. Function Structure
4. Performance Requirements
5. Security Requirements
6. Testing Requirements

## 1. Context

This template is for developing functions in a Windows Server environment (2019-2025) using PowerShell 7+. Functions must:

* Follow the Active Directory tiering model and delegation model.
* Be secure, idempotent, and scalable (100k+ objects).
* Support `ShouldProcess`, comment-based help, and Pester testing.
* Be optimized for large-scale AD/Windows environments (100,000+ objects).

## 2. Function Requirements

* `{{functionName}}`: The name of the function using approved verb-noun format (e.g., `Get-ADUserProperty`).
* `{{purpose}}`: One-line summary of function's goal.
* `{{commonParameters}}`: Specify if `Confirm`, `WhatIf`, `Verbose`, `Debug`, `ErrorAction`, `ErrorVariable`, `WarningAction`, `WarningVariable`, `OutBuffer`, `OutVariable` parameters should be included (e.g., "Confirm,WhatIf").
* `Target Environment`: Active Directory/Windows Server 2019-2022-2025/PowerShell 7.
* `{{modules}}`: List of required modules or dependencies (e.g., "ActiveDirectory, Microsoft.Graph.Users").
* `{{inputType}}`: Type of input the function accepts (e.g., `String`, `PSCustomObject`, etc.).
* `{{outputType}}`: Type of output the function returns (e.g., `PSCustomObject`, `String`, etc.).
* `{{functionality}}`: Brief description of the core functionality, including specific AD operations or system interactions.
* `{{parameters}}`: Details for specific parameters beyond common ones, including:
  * `name`: Parameter name (PascalCase).
  * `type`: Data type (e.g., `[string]`, `[int]`, `[System.Management.Automation.PSCredential]`).
  * `mandatory`: `$true` or `$false`.
  * `position`: Integer for positional parameters.
  * `pipeline`: `ValueFromPipeline` or `ValueFromPipelineByPropertyName`.
  * `description`: Purpose of the parameter.
  * `validation`: Any `Validate*` attributes (e.g., `ValidateNotNullOrEmpty`, `ValidateSet('Value1', 'Value2')`).
  * `default`: Default value if not mandatory.
* `{{examples}}`: One or more example usage scenarios.
  * `code`: PowerShell code snippet for the example.
  * `description`: Explanation of what the example does.
* `{{notes}}`: Any additional notes for the function (e.g., used cmdlets and their modules).

## 3. Function Structure

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
            'Value' | Example-Function
            Description of pipeline input example.

        .INPUTS
            [System.String]
            You can pipe a string value to the ParameterName parameter.

        .OUTPUTS
            [PSCustomObject]
            Returns a custom object with processed data.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                [Cmdlet name]                    ║ [Module/Namespace]

        .NOTES
            Version:         1.0
            DateModified:    dd/MMM/yyyy
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibarit.com
                        Eguibar IT
                        http://www.eguibarit.com

        .LINK
            [https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser](https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser)

        .COMPONENT
            User Management

        .ROLE
            Tier 2 Administrator

        .FUNCTIONALITY
            Retrieves, modifies, or creates Active Directory user objects.
    #>
```

### Basic Function Skeleton

```powershell
    function {{functionName}} {

        [CmdletBinding(
            SupportsShouldProcess = $true,
            ConfirmImpact = 'Medium'
        )]
        [OutputType([PSCustomObject])]

        param(

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 0,
                HelpMessage = 'Parameter description'
            )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript(
                { Test-IsValidDN -ObjectDN $_ },
                ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
            )]
            [Alias('DN', 'DistinguishedName')]
            [String]
            $Identity,

            [Parameter(Mandatory = $false)]
            [Switch]
            $PassThru

        )

        Begin {
            Set-StrictMode -Version Latest

            # Display function header if variables exist
            if ($null -ne $Variables -and
                $null -ne $Variables.HeaderHousekeeping) {

                $txt = ($Variables.HeaderHousekeeping -f
                    (Get-Date).ToString('dd/MMM/yyyy'),
                    $MyInvocation.Mycommand,
                    (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
                )
                Write-Verbose -Message $txt
            } #end If

            ##############################
            # Module imports

            Import-MyModule -Name ActiveDirectory -Force -Verbose:$false

            ##############################
            # Variables Definition

            [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
            [hashtable]$SplatProgress = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        } #end Begin

        Process {

            # Process logic here
            # Consider delegating logic to private/helper functions to improve readability/testability.
            # New private/helper must be relevant and useful; only use them when they encapsulate a specific functionality that can be reused or tested independently.

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

                    } #end if

                } catch [System.Exception] {

                    Write-Error -Message ('Error occurred: {0}' -f $_.Exception.Message)

                } #end try-catch

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
    } #end function {{functionName}}
```

## 4. Performance Requirements

* Support batch processing of multiple objects simultaneously.
* Minimize redundant queries to AD (cache results when appropriate).
* Use efficient filtering with LDAP filters at source rather than client-side filtering.
* Implement appropriate pagination for large result sets.
* Follow the single-responsibility principle.
* Use splatting for better readability and maintainability.
* Use `Write-Progress` for long-running operations to provide user feedback.

## 5. Security Requirements

* Never store credentials or sensitive data in plain text.
* Use SecureString for password parameters.
* Implement the least privilege principle.
* Sanitize all user input before using it in queries.
* Avoid using Invoke-Expression with user-supplied input.
* Use credential parameters with proper validation.
* Use [System.Management.Automation.PSCredential] for any user/pass input.
* Consider Get-Credential guidance when used interactively.

## 6. Testing Requirements

* Include Pester test files with naming convention [FunctionName].Tests.ps1.
* Cover parameter validation, functionality, error handling, edge cases.
* Mock external dependencies for independent testing.
* Test pipeline input scenarios.
* Test ShouldProcess functionality where implemented.
