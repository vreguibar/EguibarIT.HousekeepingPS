function Set-SemiPrivilegedUser {
    <#
        .SYNOPSIS
            Creates a new Semi-Privileged user based on the AD Delegation Model.

        .DESCRIPTION
            This function creates a new Semi-Privileged user based on the Active Directory (AD) Delegation Model.
            It checks if the provided standard user exists, and if so, it creates a
            new Semi-Privileged user with the specified account type.

        .PARAMETER SamAccountName
            Identity of the user getting the new Admin Account (Semi-Privileged user).
            [String] Valid and existing user account name in Active Directory.

        .PARAMETER AccountType
            Must specify the account type. Valid values are T0, T1, or T2.
            [String] Enforces using ValidateSet to restrict values to T0, T1, or T2.

        .PARAMETER AdminUsersDN
            Distinguished Name of the container where the Admin Accounts are located.
            [String] Valid DN in Active Directory.

        .PARAMETER Password
            Secure String containing the password of the user. In case user does not exist, it
            will be created and this password will be used. If user already exist the password will be unchanged.

        .EXAMPLE
            $Splat = @{
                SamAccountName = 'davade'
                AccountType    = 'T0'
                AdminUsersDN   = 'OU=Users,OU=Admin,DC=EguibarIT,DC=local'
                Password       = ConvertTo-SecureString -String 'P@ssword 123456' -AsPlainText -Force
            }
            Set-SemiPrivilegedUser @Splat

        .OUTPUTS
            [Microsoft.ActiveDirectory.Management.ADAccount]
            The function will return the Semi-Privileged user either if newly created or already existing.

        .EXAMPLE
            New-SemiPrivilegedUser -SamAccountName "davade" -AccountType "T0" -AdminUsersDN "OU=Admins,DC=domain,DC=com" -Password (ConvertTo-SecureString -String 'P@ssword 123456' -AsPlainText -Force)

    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([Microsoft.ActiveDirectory.Management.ADAccount])]

    param (

        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Identity of the user getting the new Admin Account (Semi-Privileged user).',
            Position = 0)]
        [Alias('Name', 'ID', 'Identity')]
        [ValidateNotNullOrEmpty()]
        $SamAccountName,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Must specify the account type. Valid values are T0 or T1 or T2',
            Position = 1)]
        [ValidateSet('T0', 'T1', 'T2')]
        [string]
        $AccountType,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Distinguished Name of the container where the Admin Accounts are located.',
            Position = 2)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $AdminUsersDN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Secure password for the Semi-Privileged user.',
            Position = 3)]
        [System.Security.SecureString]
        $Password
    )

    Begin {

        $newSamAccountName = '{0}_{1}' -f $SamAccountName, $AccountType.ToUpper()

        try {
            $stdUser = Get-ADUser -Identity $SamAccountName -Properties *
        } catch {
            Write-Error -Message ('Standard user {0} not found.' -f $SamAccountName)
            throw
        }

        # Check if Surename exists, else use SamAccountName
        if ($null -ne $stdUser.Surname) {
            $Surename = $stdUser.Surname.ToUpper()
        } else {
            $Surename = $stdUser.samAccountName
        } #end If-Else

        # Check if GivenName exists, else use $null
        if ($null -ne $stdUser.GivenName) {
            $GivenName = (Get-Culture).TextInfo.ToTitleCase($stdUser.GivenName.ToLower())

            If ($Surename -eq $GivenName) {
                # Built DisplayName
                $name = ('{0} ({1})' -f
                    $GivenName,
                    $PsBoundParameters['AccountType']
                )
            } else {
                # Built DisplayName
                $name = ('{0}, {1} ({2})' -f
                    $Surename,
                    $GivenName,
                    $PsBoundParameters['AccountType']
                )
            }
        } else {
            $GivenName = $null

            # No GivenName. Omit that on the name
            $name = ('{0} ({1})' -f
                $Surename.ToUpper(),
                $PsBoundParameters['AccountType']
            )
        } #end If-Else


        # HashTable with all params.
        $userParams = @{
            SamAccountName        = $newSamAccountName
            UserPrincipalName     = '{0}_{1}@{2}' -f $SamAccountName, $AccountType, $env:USERDNSDOMAIN
            Name                  = $name
            DisplayName           = $name
            Surname               = $Surename
            GivenName             = $GivenName
            Description           = '{0} Admin account' -f $AccountType
            Path                  = $AdminUsersDN
            Enabled               = $true
            TrustedForDelegation  = $false
            AccountNotDelegated   = $true
            ChangePasswordAtLogon = $false
            PasswordNeverExpires  = $false
            AccountPassword       = $Password
            EmployeeNumber        = $stdUser.SID.Value.ToString()
            OtherAttributes       = @{
                'employeeType'                  = $AccountType.ToUpper();
                'msNpAllowDialin'               = $false;
                'msDS-SupportedEncryptionTypes' = '24';
            }
            PassThru              = $true
            Verbose               = $PSBoundParameters['Verbose']
        }

        # Copy additional attributes from standard user
        $attributesToCopy = @(
            'Company', 'Country', 'Department', 'Division', 'EmailAddress', 'EmployeeId',
            'MobilePhone', 'Office', 'OfficePhone', 'Organization', 'OtherName',
            'POBox', 'PostalCode', 'State', 'StreetAddress', 'Title'
        )

        # Add all attributes to copy
        foreach ($attr in $attributesToCopy) {
            if ($stdUser.$attr) {
                $userParams[$attr] = $stdUser.$attr
            } #end If
        } #end Foreach

    } #end Begin

    Process {

        try {
            $existingUser = Get-ADUser -Identity $newSamAccountName -ErrorAction SilentlyContinue
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            $existingUser = $null
        } Catch {
            Write-Error -Message 'Something went wrong when trying to check if Semi-Privileged user exists or not'
        }

        try {
            if ($existingUser) {

                # Semi-Privileged User exist. Modify it!
                if ($PSCmdlet.ShouldProcess($newSamAccountName, 'Update existing Semi-Privileged user')) {

                    Write-Verbose -Message ('
                        [PROCESS]
                            The Semi-Privileged user {0} already exists.
                            Modifying the account.' -f
                        $newSamAccountName
                    )

                    # As we are using Splat var for create and update,
                    # Path works on new user, but not existing. We remove Path here
                    # Name works on new user, but not existing. We remove Name here
                    # AccountPassword works on new user, but not existing. We remove AccountPassword here
                    $userParams.Remove('Path')
                    $userParams.Remove('Name')
                    $userParams.Remove('AccountPassword')
                    $userParams.Remove('OtherAttributes')

                    # OtherAttributes is equivalent to Replace. Adding Replace here
                    $userParams.Add('Replace', @{
                            'employeeType'                  = $AccountType.ToUpper();
                            'msNpAllowDialin'               = $false;
                            'msDS-SupportedEncryptionTypes' = '24';
                        }
                    )

                    $ReturnUser = Set-ADUser -Identity $newSamAccountName @userParams

                } #end If

            } else {

                # Semi-Privileged User does not exist. Create it!
                if ($PSCmdlet.ShouldProcess($newSamAccountName, 'Creating new Semi-Privileged user')) {

                    $ReturnUser = New-ADUser @userParams

                    Write-Verbose -Message ('
                        [PROCESS]
                            Created new Semi-Privileged admin account.
                            New Admin Account {0} of type {1} was created correctly.' -f
                        $newSamAccountName,
                        $PsBoundParameters['AccountType']
                    )

                } #end If
            } #end If-Else

        } catch {
            Write-Error -Message ('Error creating/updating semi-privileged user {0}: {1}' -f $newSamAccountName, $_)
            throw
        } #end Try-Catch

    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'setting/creating Semi-Privileged account.'
        )
        Write-Verbose -Message $txt

        return $ReturnUser
    } #end End
} #end Function
