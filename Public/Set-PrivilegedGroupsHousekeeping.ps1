function Set-PrivilegedGroupsHousekeeping {
    <#
        .Synopsis
            Removes unauthorized users from privileged Active Directory groups in a specified OU.

        .DESCRIPTION
            This function audits groups in a specified Admin OU (Tier 0) and ensures that they only contain authorized users.
            Authorized users are those with a SamAccountName ending in _T0, _T1, or _T2. Any users not matching this criteria
            or not explicitly excluded are removed from these groups.

        .PARAMETER AdminGroupsDN
            The Distinguished Name of the OU where the privileged groups are located.

        .PARAMETER ExcludeList
            An array of usernames that should be excluded from removal regardless of their naming convention.

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping "OU=Groups,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping -AdminUsersDN "OU=Groups,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-PrivilegedGroupsHousekeeping -AdminUsersDN "OU=Groups,OU=Admin,DC=EguibarIT,DC=local" -ExcludeList "dvader", "hsolo"

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

    Param (

        #Param1
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminGroupsDN,

        #Param2
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'User list to be excluded from this process.',
            Position = 1)]
        [System.Collections.ArrayList]
        $ExcludeList

    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        # All objects from Source domain
        Write-Verbose -Message 'Getting the list of ALL semi-privileged groups.'
        $AllPrivGroups = Get-ADGroup -Filter * -Properties SamAccountName -SearchBase $PsBoundParameters['AdminGroupsDN'] -ErrorAction Stop

        # Check if exclusion list is provided
        if ($PSBoundParameters['ExcludeList']) {
            # If the Administrator does not exist, add it
            If (-not($ExcludeList.Contains('Administrator'))) {
                $ExcludeList.Add('Administrator')
            }

            # If the TheGood not exist, add it
            If (-not($ExcludeList.Contains('TheGood'))) {
                $ExcludeList.Add('TheGood')
            }

            # If the TheUgly not exist, add it
            If (-not($ExcludeList.Contains('TheUgly'))) {
                $ExcludeList.Add('TheUgly')
            }

            # If the krbtgt not exist, add it
            If (-not($ExcludeList.Contains('krbtgt'))) {
                $ExcludeList.Add('krbtgt')
            }
        } #end If

        # Item Counter
        [int]$i = 0

        # Total Objects Found
        [int]$TotalObjectsFound = $AllPrivGroups.Count

        # Removed Users counter
        [int]$userRemovedCount = 0

        Write-Verbose ('Iterate through each item returned. Total found: {0}' -f $TotalObjectsFound)
    } #end Begin

    Process {
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

            # Get members of current group
            $groupMembers = Get-ADGroupMember -Identity $group -ErrorAction Continue | Where-Object { $_.objectClass -eq 'user' }

            # iterate group members
            foreach ($member in $groupMembers) {

                # process exclude list, ending on _T0,_T1 & _T2 and ShouldProcess
                if ($ShouldProcess -and $member.SamAccountName -notmatch '_T[0-2]$' -and $ExcludeList -notcontains $member.SamAccountName) {

                    Remove-ADGroupMember -Identity $group -Members $member -Confirm:$false -ErrorAction Continue
                    Write-Verbose ('Removed unauthorized user {0} from group {1}.' -f $member.SamAccountName, $group.SamAccountName)
                    $userRemovedCount++
                } #end If
            } #end ForEach
        } #end ForEach

    } #end Process

    End {
        $Constants.NL
        Write-Verbose 'A semi-privileged and/or Privileged group can ONLY contain semi-privileged and/or Privileged accounts.'
        Write-Verbose 'Any userID which does not complies with this statement, will automatically be removed from the group.'
        $Constants.NL
        Write-Verbose ('{0} users were removed from Privileged/Semi-Privileged groups.' -f $userRemovedCount)

        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished setting semi-privileged and/or Privileged group housekeeping."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
