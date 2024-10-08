function Set-PrivilegedGroupsHousekeeping {
    <#
        .Synopsis
            Removes unauthorized users from privileged Active Directory groups in a specified OU.

        .DESCRIPTION
            This function audits groups in a specified Admin OU (Tier 0) and ensures that they only contain authorized users.
            Authorized users are those with a SamAccountName ending in _T0, _T1, or _T2 or those who have the EmployeeType as 'T0' or 'T1' or 'T2'. Any users not matching this criteria
            or not explicitly excluded are removed from these groups.

        .PARAMETER AdminGroupsDN
            The Distinguished Name of the OU where the privileged groups are located.

        .PARAMETER ExcludeList
            An array of usernames that should be excluded from removal regardless of their naming convention.

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping "OU=Groups,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping -AdminGroupsDN "OU=Groups,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping -AdminGroupsDN "OU=Groups,OU=Admin,DC=EguibarIT,DC=local" -ExcludeList "dvader", "hsolo"

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADGroup                            | ActiveDirectory
                Get-ADGroupMember                      | ActiveDirectory
                Remove-ADGroupMember                   | ActiveDirectory
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
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminGroupsDN,

        #Param2
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

        # Item Counter
        [int]$i = 0

        # Total Objects Found
        [int]$TotalObjectsFound = $AllPrivGroups.Count

        # Removed Users counter
        [int]$userRemovedCount = 0

    } #end Begin

    Process {
        # All objects from Source domain
        Write-Verbose -Message 'Getting the list of ALL semi-privileged groups.'
        $Splat = @{
            Filter      = '*'
            Properties  = 'SamAccountName'
            SearchBase  = $PsBoundParameters['AdminGroupsDN']
            ErrorAction = 'Stop'
        }
        $AllPrivGroups = Get-ADGroup @Splat

        $TotalObjectsFound = $AllPrivGroups.Count
        [int]$userRemovedCount = 0

        Write-Verbose -Message ('Iterate through each item returned. Total found: {0}' -f $TotalObjectsFound)

        # Iterate all found groups
        Foreach ($group in $AllPrivGroups) {
            $i ++

            # Display the progress bar
            $parameters = @{
                Activity        = 'Checking group membership'
                Status          = "Working on item No. $i from $TotalObjectsFound"
                PercentComplete = ($i / $TotalObjectsFound * 100)
            }
            Write-Progress @parameters

            # Exclude "Domain Users" group
            If (-Not ($group.SID.value -like '*-513')) {

                # Get members of current group
                $Splat = @{
                    Identity    = $group
                    ErrorAction = 'Continue'
                }
                $groupMembers = Get-ADGroupMember @Splat | Where-Object { $_.objectClass -eq 'user' }

                # iterate group members
                foreach ($member in $groupMembers) {

                    if ($member.SamAccountName -notmatch '_T[0-2]$' -and $ExcludeList -notcontains $member.SamAccountName) {

                        if ($PSCmdlet.ShouldProcess("$($member.SamAccountName) in $($group.SamAccountName)", 'Remove unauthorized member')) {

                            Remove-ADGroupMember -Identity $group -Members $member -Confirm:$false -ErrorAction Stop

                            Write-Verbose -Message ('
                                Removed unauthorized user {0}
                                from group {1}' -f
                                $member.SamAccountName, $group.SamAccountName
                            )

                            $userRemovedCount++
                        } #end If ShouldProcess
                    } #end If

                } #end If "Domain Users"
            } #end ForEach
        } #end ForEach

    } #end Process

    End {
        $Constants.NL
        Write-Verbose ('
            A semi-privileged and/or Privileged group can ONLY contain semi-privileged and/or Privileged accounts.
            Any userID which does not complies with this statement, will automatically be removed from the group.

            {0} users were removed from Privileged/Semi-Privileged groups.' -f
            $userRemovedCount
        )

        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'setting semi-privileged and/or Privileged group housekeeping.'
        )
        Write-Verbose -Message $txt
    } #end End
}
