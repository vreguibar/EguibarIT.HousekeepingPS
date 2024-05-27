Function Get-RandomPassword {
    <#
        .SYNOPSIS
            Generates a New password with varying length and Complexity,
        .DESCRIPTION
            This function generates a random password. The complexity parameter controls the character sets included in the password:
            1 - Lowercase letters only.
            2 - Lowercase and uppercase letters.
            3 - Lowercase, uppercase letters, and numbers.
            4 - Lowercase, uppercase letters, numbers, and punctuation.

        .PARAMETER PasswordLength
            Specifies the length of the password. The default is 15 characters.

        .PARAMETER Complexity
            Specifies the complexity of the password:
            1 - Lowercase letters.
            2 - Upper and lowercase letters.
            3 - Upper and lowercase letters and numbers.
            4 - Includes punctuation.
            The default complexity is 3 (includes upper, lower case letters, and numbers).

        .EXAMPLE
            Get-RandomPassword
            Generates a 15-character long password including uppercase, lowercase letters, and numbers.

        .EXAMPLE
            Get-RandomPassword -PasswordLength 15 -Complexity 4
            Generates a 15-character long password that includes uppercase, lowercase letters, numbers, and punctuation.

        .EXAMPLE
            $MYPASSWORD = CONVERTTO-SECURESTRING (Get-RandomPassword 8 2) -asplaintext -force
            Create a new 8 Character Password of Uppercase/Lowercase and store
            as a Secure.String in Variable called $MYPASSWORD

        .NOTES
            The Complexity falls into the following setup for the Complexity level
            1 - Pure lowercase Ascii
            2 - Mix Uppercase and Lowercase Ascii
            3 - Ascii Upper/Lower with Numbers
            4 - Ascii Upper/Lower with Numbers and Punctuation

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    31/Mar/2015
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = 'low')]
    [OutputType([String])]

    Param (
        # Param1 INT indicating password length
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Specifies the length of the password. The default is 15 characters.',
            Position = 0)]
        [ValidateRange(1, 256)]
        [PSDefaultValue(Help = 'Default Value is 15 characters')]
        [Alias('Size', 'Characters')]
        [int]
        $PasswordLength = 15,

        # Param2 INT indicating complexity
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Specifies the complexity of the password. Default is 3. 1- Pure lowercase Ascii. 2- Mix Uppercase and Lowercase Ascii. 3- Ascii Upper/Lower with Numbers. 4- Ascii Upper/Lower with Numbers and Punctuation',
            Position = 1)]
        [ValidateRange(1, 4)]
        [PSDefaultValue(Help = 'Default Value is 3 characters')]
        [Alias('Difficulty')]
        [int]
        $Complexity = 3
    )

    Begin {

        Write-Verbose -Message '|=> ************************************************************************ <=|'
        Write-Verbose -Message (Get-Date).ToShortDateString()
        Write-Verbose -Message ('  Starting: {0}' -f $MyInvocation.Mycommand)
        Write-Verbose -Message ('Parameters used by the function... {0}' -f (Get-FunctionDisplay $PsBoundParameters -Verbose:$False))
        #Write-Verbose -Message ('Password length... {0} | Complexity... {1}' -f $PasswordLength, $Complexity)

        ##############################
        # Variables Definition

        # Characters that can be used for generating the password
        # Some are remved to avoid confusion
        # O, l, I
        $characterSets = @(
            [char[]]'abcdefghijkmnopqrstuvwxyz', # Lowercase
            [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ', # Uppercase
            [char[]]'0123456789', # Numbers
            [char[]]'!@#$%^&*()_-+=[]{}|;:,.<>?'  # Punctuation
        )

        # Array to hold characters
        [System.Collections.ArrayList]$password = [System.Collections.ArrayList]::new()

        # Nullify the Variable holding the password
        [string]$NewPassword = $null

    } #end Begin

    Process {

        # iterate elements through password length
        for ($i = 0; $i -lt $PasswordLength; $i++) {

            # select randomly the set
            $set = $characterSets[0..($Complexity - 1)] | Get-Random

            # Select a random character from the given set
            $character = $set | Get-Random

            # Add character to ArrayList
            $password.Add($character) | Out-Null
        } #end For

        # Join characters for the final password
        $NewPassword = -join $password
    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished generating Random Password."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''

        Return $NewPassword
    } #end End
}
