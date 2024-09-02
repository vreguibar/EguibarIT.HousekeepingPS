function Test-EmailAddress {

    [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess = $false)]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'String to be validated as email address',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $EmailAddress
    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Variables Definition

        [bool]$isValid = $false

        [regex]$emailRegex = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'

        Write-Verbose -Message 'Begin block: Regex pattern for email validation initialized.'

    } #end Begin

    Process {

        Try {

            # Perform the actual validation
            $isValid = $emailRegex.IsMatch($EmailAddress)

            # Provide verbose output
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose -Message ('Email validation result: {0}' -f $isValid)
            } #end If

        } catch {
            # Handle exceptions gracefully
            Write-Error -Message $_
        } #end Try-Catch

    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'testing email.'
        )
        Write-Verbose -Message $txt

        return $isValid
    } #end End
}
