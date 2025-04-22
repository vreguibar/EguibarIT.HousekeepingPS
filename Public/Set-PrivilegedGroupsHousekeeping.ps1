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
                Name                                   ║ Module/Namespace
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ADGroup                            ║ ActiveDirectory
                Get-ADGroupMember                      ║ ActiveDirectory
                Get-ADUser                             ║ ActiveDirectory
                Remove-ADGroupMember                   ║ ActiveDirectory
                Import-Module                          ║ Microsoft.PowerShell.Core
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Progress                         ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS
                Test-IsValidDN                         ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.1
            DateModified:    17/Jun/2023
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

        .COMPONENT
            Active Directory

        .ROLE
            Security

        .FUNCTIONALITY
            Privileged Group Management
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]

    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 0)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminGroupsDN,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'User list to be excluded from this process.',
            Position = 1)]
        [System.Collections.Generic.List[String]]
        $ExcludeList
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
        # Module Import
        Import-MyModule -Name ActiveDirectory -Force -Verbose:$false

        ##############################
        # Variables Definition

        # Parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # If parameter is not passed, initialize as a new list
        if (-not $PSBoundParameters.ContainsKey('ExcludeList')) {
            $ExcludeList = [System.Collections.Generic.List[String]]::New()
        } #end If

        # Add well-known admin accounts to exclusion list
        $wellKnownUserSids = @{
            'S-1-5-21-*-500' = 'Administrator'
            'S-1-5-21-*-502' = 'krbtgt'
        }

        foreach ($sid in $wellKnownUserSids.Keys) {
            try {
                # For these SIDs, we always need to use the wildcard approach
                $users = Get-ADUser -Filter * -Properties SID |
                    Where-Object -FilterScript { $_.SID -like $sid }

                foreach ($item in $users) {
                    If ($item.SamAccountName -notin $ExcludeList) {
                        $ExcludeList.Add($item.SamAccountName) | Out-Null
                        Write-Verbose -Message ('Added {0} to exclusion list (SID: {1})' -f $item.SamAccountName, $item.SID)
                    } #end If
                } #end ForEach
            } catch {
                Write-Warning -Message ('Error finding users with SID pattern {0}: {1}' -f $sid, $_.Exception.Message)
            } #end Try-Catch
        } #end ForEach

        # Item Counter
        [int]$i = 0

        # Removed Users counter
        [int]$userRemovedCount = 0
    } #end Begin

    Process {
        try {
            # All objects from Source domain
            Write-Verbose -Message ('Getting the list of ALL privileged groups in {0}.' -f $AdminGroupsDN)
            $Splat = @{
                Filter      = '*'
                Properties  = 'SamAccountName'
                SearchBase  = $AdminGroupsDN
                ErrorAction = 'Stop'
            }
            $AllPrivGroups = Get-ADGroup @Splat

            $TotalObjectsFound = $AllPrivGroups.Count
            Write-Verbose -Message ('Found {0} groups to process.' -f $TotalObjectsFound)

            # Iterate all found groups
            foreach ($group in $AllPrivGroups) {
                $i++

                # Display the progress bar
                $parameters = @{
                    Activity        = 'Checking group membership'
                    Status          = "Working on group: $($group.Name) ($i of $TotalObjectsFound)"
                    PercentComplete = ($i / $TotalObjectsFound * 100)
                }
                Write-Progress @parameters

                # Exclude "Domain Users" group (SID ending with -513)
                if (-not ($group.SID.Value -like '*-513')) {
                    try {
                        # Get members of current group
                        $Splat = @{
                            Identity    = $group
                            ErrorAction = 'Stop'
                        }
                        $groupMembers = Get-ADGroupMember @Splat |
                            Where-Object { $_.objectClass -eq 'user' }

                        if ($groupMembers.Count -eq 0) {
                            Write-Verbose -Message ('Group {0} has no user members.' -f $group.SamAccountName)
                            continue
                        }

                        # Iterate group members
                        foreach ($member in $groupMembers) {
                            try {
                                # Get full user object to check EmployeeType attribute
                                $user = Get-ADUser -Identity $member -Properties EmployeeType -ErrorAction Stop

                                $isAuthorized = $false

                                # Check if user matches naming convention (_T0, _T1, _T2)
                                if ($user.SamAccountName -match '_T[0-2]$') {
                                    $isAuthorized = $true
                                }

                                # Check if user has proper EmployeeType attribute
                                if (-not $isAuthorized -and
                                    $null -ne $user.EmployeeType -and
                                    $user.EmployeeType -match '^T[0-2]$') {
                                    $isAuthorized = $true
                                }

                                # Check if user is in exclusion list
                                if (-not $isAuthorized -and $ExcludeList -contains $user.SamAccountName) {
                                    $isAuthorized = $true
                                }

                                # Remove unauthorized users
                                if (-not $isAuthorized) {
                                    if ($PSCmdlet.ShouldProcess(
                                            "User $($user.SamAccountName) from group $($group.SamAccountName)",
                                            'Remove unauthorized member')) {

                                        $Splat = @{
                                            Identity    = $group
                                            Members     = $user
                                            Confirm     = $false
                                            ErrorAction = 'Stop'
                                        }
                                        Remove-ADGroupMember @Splat

                                        Write-Verbose -Message ('Removed unauthorized user {0} from group {1}' -f
                                            $user.SamAccountName, $group.SamAccountName)

                                        $userRemovedCount++
                                    } #end If ShouldProcess
                                } #end If not authorized
                            } catch {
                                Write-Warning -Message ('Error processing user {0}: {1}' -f $member.SamAccountName, $_.Exception.Message)
                            } #end Try-Catch
                        } #end ForEach member
                    } catch {
                        Write-Warning -Message ('Error processing group {0}: {1}' -f $group.SamAccountName, $_.Exception.Message)
                    } #end Try-Catch
                } else {
                    Write-Verbose -Message ('Skipping Domain Users group: {0}' -f $group.SamAccountName)
                } #end If not Domain Users
            } #end ForEach group
        } catch {
            Write-Error -Message ('Error retrieving groups: {0}' -f $_.Exception.Message)
        } #end Try-Catch
    } #end Process

    End {
        Write-Progress -Activity 'Checking group membership' -Completed

        # Display results
        Write-Verbose -Message @"
A privileged group can ONLY contain privileged accounts.
Any user which does not comply with this requirement will automatically be removed from the group.

$userRemovedCount users were removed from Privileged/Semi-Privileged groups.
"@

        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'processing privileged group housekeeping.'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end End
} #end function Set-PrivilegedGroupsHousekeeping
