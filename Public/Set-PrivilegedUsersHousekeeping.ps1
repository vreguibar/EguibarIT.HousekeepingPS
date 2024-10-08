function Set-PrivilegedUsersHousekeeping {
    <#
        .SYNOPSIS
            Organizes user accounts into corresponding admin tier groups and optionally disables non-standard users.

        .DESCRIPTION
            This function scans all user accounts in a specified OU and assigns them to the respective
            administrative tier groups based on their naming conventions. Users not adhering to the standard naming
            conventions can optionally be disabled.

        .PARAMETER AdminUsersDN
            Specifies the Distinguished Name of the OU where admin user accounts are stored.

        .PARAMETER DisableNonStandardUsers
            If this switch is provided, the function will disable user accounts that do not follow the standard naming conventions.

        .EXAMPLE
            Set-PrivilegedUsersHousekeeping -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local" -DisableNonStandardUsers
            This example will classify users in the specified OU and disable non-standard users.

        .EXAMPLE
            Set-PrivilegedUsersHousekeeping -AdminUsersDN 'OU=Users,OU=Admin,DC=EguibarIT,DC=local' -Tier0Group 'SG_Tier0Admins' -Tier1Group 'SG_Tier1Admins' -Tier2Group 'SG_Tier2Admins' -ExcludeList @('TheGood', 'TheUgly') -DisableNonStandardUsers -Verbose

        .EXAMPLE
            Set-PrivilegedUsersHousekeeping -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local"

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADUser                             | ActiveDirectory
                Get-ADGroupMember                      | ActiveDirectory
                Add-ADGroupMember                      | ActiveDirectory
                Disable-ADAccount                      | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Progress                         | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-AdObjectType                       | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    20/Jul/2017
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]

    Param (

        #Param1
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Admin User Account OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminUsersDN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Group containing all Tier0 Semi-Privileged/Privileged users.',
            Position = 1)]
        $Tier0Group,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Group containing all Tier1 Semi-Privileged/Privileged users.',
            Position = 2)]
        $Tier1Group,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Group containing all Tier2 Semi-Privileged/Privileged users.',
            Position = 3)]
        $Tier2Group,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'User list to be excluded from this process.',
            Position = 4)]
        [System.Collections.Generic.List[string]]
        $ExcludeList,

        #Param2
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'If present, will disable all Non-Standard users.',
            Position = 5)]
        [switch]
        $DisableNonStandardUsers

    )
    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        Import-MyModule ActiveDirectory

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        [int]$i = 0

        # If parameter is parsed, initialize variable to be used by default objects
        If (-Not $PSBoundParameters.ContainsKey('ExcludeList')) {
            $ExcludeList = [System.Collections.Generic.List[String]]::New()
        } #end If

        $wellKnownUserSids = @{
            'S-1-5-21-*-500' = 'Administrator'
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


        # Fetch all user accounts in the given OU
        try {
            $Splat = @{
                Filter      = '*'
                Properties  = 'EmployeeType'
                SearchBase  = $PsBoundParameters['AdminUsersDN']
                ErrorAction = 'Stop'
            }
            $AllPrivUsers = Get-ADUser @Splat
        } catch {
            Write-Error -Message ('Failed to retrieve users: {0}' -f $_)
            return
        } #end Try-Catch

        Write-Verbose -Message ('
            Found {0} semi privileged accounts (_T0, _T1, _T2)
            in {1}' -f
            $AllPrivUsers.Count, $PsBoundParameters['AdminUsersDN']
        )

        # Initialize and Get each tier group
        $tierGroups = @{
            T0 = Get-AdObjectType -Identity $PsBoundParameters['Tier0Group']

            T1 = if ($Tier1Group) {
                Get-AdObjectType -Identity $PsBoundParameters['Tier1Group']
            }

            T2 = if ($Tier2Group) {
                Get-AdObjectType -Identity $PsBoundParameters['Tier2Group']
            }
        }

        # Define group per each tier to hold members
        $tierMembers = @{
            T0 = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            T1 = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            T2 = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        } # end tierMembers


        # Populate existing members of tier groups
        foreach ($tier in $tierGroups.Keys) {
            if ($tierGroups[$tier]) {
                Get-ADGroupMember -Identity $tierGroups[$tier] | ForEach-Object {
                    $tierMembers[$tier].Add($_.SamAccountName)
                }
            } #end If
        } #end Foreach

    } #end Begin

    Process {

        # Iterate all found users
        Foreach ($user in $AllPrivUsers) {
            $i ++

            # Display the progress bar
            $parameters = @{
                Activity        = 'Checking Privileged Users'
                Status          = ('Working on item No. {0} from {1}' -f $i, $AllPrivUsers.Count)
                PercentComplete = ($i / $AllPrivUsers.Count * 100)
            }
            Write-Progress @parameters

            # Check Exclude list
            if ($user.SamAccountName -in $ExcludeList) {
                continue
            }

            # Check if EmployeeType is defined. Otherwise use last 3 characters of SamAccountName
            $tier = if ($user.EmployeeType -in @('T0', 'T1', 'T2')) {
                $user.EmployeeType
            } else {
                $user.SamAccountName -replace '.*(_T[0-2])$', '$1' -replace '_', ''
            } #end If-Else

            # Check compliance on the user. Disable if needed.
            if ($tier -notin @('T0', 'T1', 'T2')) {

                Write-Warning -Message ('
                    User {0}
                    has an invalid tier: {1}' -f
                    $user.SamAccountName, $tier
                )
                if ($DisableNonStandardUsers -and $PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable non-standard user')) {

                    Disable-ADAccount -Identity $user
                    Write-Verbose -Message ('Account {0} was disabled due to compliance.' -f $user.SamAccountName)

                } #end If
                continue
            } #end If-Else

            # Add Semi-Privileged users to the corresponding group
            if (-not $tierMembers[$tier].Contains($user.SamAccountName)) {

                #Get current group
                $groupName = $tierGroups[$tier].Name

                if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Add to $groupName")) {

                    # Add user to the group
                    Add-ADGroupMember -Identity $tierGroups[$tier] -Members $user

                    Write-Verbose -Message ('{0} - {1} added to {2}' -f $tier, $user.SamAccountName, $groupName)

                    $tierMembers[$tier].Add($user.SamAccountName)

                } # end if
            } # end if

        } #end ForEach
    } #end Process

    End {
        $summary = $tierMembers.GetEnumerator() | ForEach-Object {
            '   {0} Members: {1}' -f $_.Key, $_.Value.Count
        } # end ForEach-Object
        Write-Verbose -Message ('Summary:{0}{1}' -f $Constants.NL, ($summary -join $Constants.NL))


        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'setting semi-privileged and/or Privileged users housekeeping.'
        )
        Write-Verbose -Message $txt
    } #end End
} #end Function
