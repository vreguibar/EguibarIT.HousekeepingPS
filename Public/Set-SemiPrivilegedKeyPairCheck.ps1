Function Set-SemiPrivilegedKeyPairCheck {

    <#
        .SYNOPSIS
            Manage Semi-Privileged Users by disabling or deleting based on conditions.

        .DESCRIPTION
            This function processes a list of semi-privileged users in Active Directory, checks exclusion lists,
            and either disables or deletes users based on the associated non-privileged user's status.

        .PARAMETER AdminUsersDN
            The distinguished name (DN) of the OU that contains the semi-privileged users.

        .PARAMETER ExcludeList
            A list of users to exclude from processing. Defaults to an internal list if not provided.

        .OUTPUTS
            List of users that were disabled or deleted.

            [PSCustomObject] with the following properties:
            - DisabledUsers: [System.Collections.Generic.List[String]] List of disabled user SamAccountNames
            - DeletedUsers: [System.Collections.Generic.List[String]] List of deleted user SamAccountNames

        .EXAMPLE
            Set-SemiPrivilegedKeyPairCheck -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-SemiPrivilegedKeyPairCheck -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local" -ExcludeList "davader", "hasolo"

        .EXAMPLE
            "OU=Users,OU=Admin,DC=EguibarIT,DC=local" | Set-SemiPrivilegedKeyPairCheck
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]

    param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Distinguished Name of the container where the Admin Accounts are located.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $AdminUsersDN,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'User list to be excluded from this process.',
            Position = 1)]
        [System.Collections.Generic.List[String]]
        $ExcludeList

    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        Import-MyModule ActiveDirectory


        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Initialize lists to track actions
        $DisableList = [System.Collections.Generic.List[String]]::New()
        $DeleteList = [System.Collections.Generic.List[String]]::New()

        # Progress bar initialization
        $ProgressId = 0
        $Activity = 'Processing Semi-Privileged Users'
        [int]$i = 0


        # If parameter is parsed, initialize variable to be used by default objects
        If (-Not $PSBoundParameters.ContainsKey('ExcludeList')) {
            $ExcludeList = [System.Collections.Generic.List[String]]::New()
        } #end If

        $wellKnownUserSids = @{
            'S-1-5-21-*-500' = 'Administrator'
            'S-1-5-21-*-501' = 'Guest'
            'S-1-5-21-*-502' = 'krbtgt'
        }

        foreach ($sid in $wellKnownUserSids.Keys) {
            # For these SIDs, we always need to use the wildcard approach
            $users = Get-ADUser -Filter * | Where-Object -FilterScript { $_.SID -like $sid }

            foreach ($item in $users) {
                If ($item.SamAccountName -notin $ExcludeList) {
                    $ExcludeList.Add($item.SamAccountName) | Out-Null
                }
            } # end foreach

        } #end Foreach

    } #end Begin

    Process {

        # Set up Active Directory context
        try {
            $Splat = @{
                Filter     = '*'
                SearchBase = $AdminUsersDN
                Property   = 'SamAccountName', 'employeeNumber', 'Enabled'
            }
            $AllPrivUsers = Get-ADUser @Splat
        } catch {
            Write-Error -Message ('Error retrieving users from the provided DN: {0}' -f $_)
            return
        }

        if ($AllPrivUsers.Count -eq 0) {
            Write-Verbose -Message 'No Privileged/Semi-Privileged users found in the given Distinguished Name container.'
            return
        } else {
            Write-Verbose -Message ('INFO - Found {0} Privileged/Semi-Privileged users.' -f $AllPrivUsers.Count)
        }

        # Iterate through each semi-privileged user
        foreach ($semiPrivilegedUser in $AllPrivUsers) {
            $i++
            $PercentComplete = [math]::Round(($i / $AllPrivUsers.Count) * 100)

            # Update progress bar
            $Splat = @{
                Id              = $ProgressId
                Activity        = $Activity
                Status          = ('Processing {0} (% Complete: {1}%)' -f $semiPrivilegedUser.SamAccountName, $PercentComplete)
                PercentComplete = $PercentComplete
            }
            Write-Progress @Splat

            # Skip users in the exclusion list
            if ($semiPrivilegedUser.SamAccountName -in $ExcludeList) {
                Write-Verbose -Message ('Skipping excluded user: {0}' -f $semiPrivilegedUser.SamAccountName)
                continue
            }

            # Flags for account actions
            [bool]$DisableSemiPrivilegedUser = $false
            [bool]$DeleteSemiPrivilegedUser = $false

            # Check if employeeNumber is null (this implies deletion)
            if (-not $semiPrivilegedUser.employeeNumber) {

                Write-Warning -Message ('
                    User {0} has no linked non-privileged user (employeeNumber is null).
                    Marking for deletion.' -f
                    $semiPrivilegedUser.SamAccountName
                )
                $DeleteSemiPrivilegedUser = $true

            } else {

                try {
                    # Retrieve the non-privileged user by SID
                    $Splat = @{
                        Identity    = $semiPrivilegedUser.employeeNumber
                        ErrorAction = 'SilentlyContinue'
                    }
                    $nonPrivilegedUser = Get-ADUser @Splat

                    # Check if non-privileged user is disabled
                    if (-not $nonPrivilegedUser.Enabled) {
                        Write-Warning -Message ('
                            Non-Privileged user {0} is disabled.
                            Marking semi-privileged user for disable.' -f
                            $nonPrivilegedUser.SamAccountName
                        )
                        $DisableSemiPrivilegedUser = $true
                    } #end If Enabled

                } catch {

                    Write-Warning -Message ('
                        Non-Privileged user not found for {0}.
                        Marking for deletion.' -f
                        $semiPrivilegedUser.SamAccountName
                    )
                    $DeleteSemiPrivilegedUser = $true

                } #end Try-Catch

                Write-Verbose -Message ('Non-privileged user found: {0}' -f $nonPrivilegedUser.SamAccountName)

            } #end If-Else

            # Disable Semi-Privileged Account
            if ($DisableSemiPrivilegedUser -and $PSCmdlet.ShouldProcess($semiPrivilegedUser.SamAccountName, 'Disable Semi-Privileged Account')) {
                try {

                    Set-ADUser -Identity $semiPrivilegedUser.SamAccountName -Enabled $false
                    $DisableList.Add($semiPrivilegedUser.SamAccountName)

                } catch {
                    Write-Error ('Failed to disable user {0}: {1}' -f $semiPrivilegedUser.SamAccountName, $_)
                } #end Try-Catch
            } #end If

            # Delete Semi-Privileged Account
            if ($DeleteSemiPrivilegedUser -and $PSCmdlet.ShouldProcess($semiPrivilegedUser.SamAccountName, 'Delete Semi-Privileged Account')) {
                try {

                    Remove-ADUser -Identity $semiPrivilegedUser.SamAccountName
                    $DeleteList.Add($semiPrivilegedUser.SamAccountName)

                } catch {
                    Write-Error -Message ('Failed to delete user {0}: {1}' -f $semiPrivilegedUser.SamAccountName, $_)
                } #end Try-Catch
            } #end If
        } #end Foreach
    } #end Process

    End {
        Write-Progress -Id $ProgressId -Activity $Activity -Completed

        # Output summary of actions
        Write-Verbose -Message ('
            Summary of actions:

            Total users disabled...: {0}
            Total users deleted....: {1}' -f
            $DisableList.Count, $DeleteList.Count
        )

        # List disabled users
        if ($DisableList.Count -gt 0) {
            Write-Verbose 'Disabled users:'
            $DisableList | ForEach-Object { $_ }
        }

        # List deleted users
        if ($DeleteList.Count -gt 0) {
            Write-Verbose 'Deleted users:'
            $DeleteList | ForEach-Object { $_ }
        }

        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'checking semi-privileged and/or Privileged user Key-Pair.'
        )
        Write-Verbose -Message $txt

        # Return a custom object with the results
        [PSCustomObject]@{
            DisabledUsers = $DisableList
            DeletedUsers  = $DeleteList
        }
    } #end End
} #end Function Set-SemiPrivilegedKeyPairCheck
