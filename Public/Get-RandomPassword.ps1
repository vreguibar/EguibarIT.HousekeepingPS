Function Get-RandomPassword {
    <#
        .SYNOPSIS
            Generates a cryptographically secure random password with configurable length and complexity.

        .DESCRIPTION
            This function generates a cryptographically secure random password using System.Security.Cryptography.
            The complexity parameter controls the character sets included in the password:
            1 - Lowercase letters only
            2 - Lowercase and uppercase letters
            3 - Lowercase, uppercase letters, and numbers
            4 - Lowercase, uppercase letters, numbers, and special characters

            The function ensures:
            - Cryptographic randomness using RNGCryptoServiceProvider
            - At least one character from each required character set
            - Configurable password length and complexity
            - No ambiguous characters (O, l, I, 1, 0)
            - Compliance with common password policies

        .PARAMETER PasswordLength
            Specifies the length of the password. Default is 15 characters.
            Valid range: 4-256 characters.

        .PARAMETER Complexity
            Specifies the complexity level of the password:
            1 - Lowercase letters only
            2 - Upper and lowercase letters
            3 - Upper/lowercase letters and numbers (Default)
            4 - Letters, numbers, and special characters
            Valid range: 1-4

        .OUTPUTS
            [String] The generated password.

        .EXAMPLE
            Get-RandomPassword
            Generates a 15-character password with default complexity (level 3).

        .EXAMPLE
            Get-RandomPassword -PasswordLength 20 -Complexity 4
            Generates a 20-character password with maximum complexity.

        .EXAMPLE
            $SecurePassword = ConvertTo-SecureString (Get-RandomPassword -PasswordLength 16) -AsPlainText -Force
            Generates a password and converts it to a SecureString.

        .NOTES
            Used Functions:
                Name                                   ║ Module
                ═══════════════════════════════════════╬══════════════════════════════
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Debug                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.1
            DateModified:    08/Apr/2025
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'low'
    )]
    [OutputType([String])]

    Param (
        # Param1 INT indicating password length
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Specifies the length of the password. The default is 15 characters and minimum of 4.',
            Position = 0)]
        [ValidateRange(4, 256)]
        [PSDefaultValue(Help = 'Default Value is 15 characters',
            Value = 15)]
        [Alias('Size', 'Characters')]
        [int]
        $PasswordLength,

        # Param2 INT indicating complexity
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Specifies the complexity of the password. Default is 3.
                1- Pure lowercase Ascii.
                2- Mix Uppercase and Lowercase Ascii.
                3- Ascii Upper/Lower with Numbers.
                4- Ascii Upper/Lower with Numbers and Punctuation',
            Position = 1)]
        [ValidateRange(1, 4)]
        [PSDefaultValue(Help = 'Default Value is 3 characters',
            Value = 3)]
        [Alias('Level', 'Difficulty')]
        [int]
        $Complexity
    )

    Begin {
        Set-StrictMode -Version Latest

        # Initialize logging
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports


        ##############################
        # Variables Definition

        # Characters that can be used for generating the password
        # Some are remved to avoid confusion
        # O, l, I
        $characterSets = @(
            [char[]]'abcdefghijkmnopqrstuvwxyz', # Lowercase excluding 'l'
            [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ', # Uppercase Excluding 'O', 'I'
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
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'generating Random Password.'
            )
            Write-Verbose -Message $txt
        } #end If

        Return $NewPassword
    } #end End
}
