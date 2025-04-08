function Test-EmailAddress {

    <#
        .SYNOPSIS
            Validates if a string is a properly formatted email address.

        .DESCRIPTION
            This function uses regular expression pattern matching to validate
            if a provided string conforms to standard email address format.
            It is part of the EguibarIT.HousekeepingPS module for AD management.

        .PARAMETER EmailAddress
            String to be validated as email address. Must not be null or empty.
            Supports pipeline input.

        .EXAMPLE
            Test-EmailAddress -EmailAddress "user@domain.com"
            Returns: True

        .EXAMPLE
            "invalid.email" | Test-EmailAddress
            Returns: False

        .EXAMPLE
            Get-ADUser -Filter * | Select-Object UserPrincipalName | Test-EmailAddress
            Validates UPN for all AD users as email addresses

        .OUTPUTS
            [System.Boolean]
            True if email is valid, False otherwise

        .NOTES
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $false
    )]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'String to be validated as email address',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Mail', 'Address', 'Email')]
        [string]
        $EmailAddress
    )

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
        # Variables Definition

        [bool]$isValid = $false

        Write-Verbose -Message 'Begin block: Regex pattern for email validation initialized.'

    } #end Begin

    Process {

        Try {

            # Trim any whitespace
            $EmailAddress = $EmailAddress.Trim()

            # Check length constraints
            if ($EmailAddress.Length -gt 254) {
                Write-Warning -Message ('Email exceeds maximum length: {0}' -f $EmailAddress)
                return $false
            } #end If

            # Perform the actual validation
            $isValid = $Constants.EmailRegEx.IsMatch($EmailAddress)

            # Provide verbose output
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose -Message ('Email validation result: {0}' -f $isValid)
            } #end If

        } catch {
            # Handle exceptions gracefully
            Write-Error -Message ('Email validation failed: {0}' -f $_.Exception.Message)
            $isValid = $false
        } #end Try-Catch

    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'testing email.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $isValid
    } #end End
} #end Function Test-EmailAddress
