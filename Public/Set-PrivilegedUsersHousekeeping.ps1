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

    Param (

        #Param1
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin User Account OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminUsersDN,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Group containing all Tier0 Semi-Privileged/Privileged users.',
            Position = 1)]
        $Tier0Group,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Group containing all Tier1 Semi-Privileged/Privileged users.',
            Position = 2)]
        $Tier1Group,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Group containing all Tier2 Semi-Privileged/Privileged users.',
            Position = 3)]
        $Tier2Group,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'User list to be excluded from this process.',
            Position = 4)]
        [System.Collections.ArrayList]
        $ExcludeList,

        #Param2
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'If present, will disable all Non-Standard users.',
            Position = 5)]
        [switch]
        $DisableNonStandardUsers

    )
    Begin {
        $txt = ($constants.Header -f
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

        # Check if exclusion list is provided
        if ($PSBoundParameters['ExcludeList']) {
            # If the Administrator does not exist, add it
            $TmpAdmin = Get-ADUser -Filter * | Where-Object { $_.SID -like 'S-1-5-21-*-500' }
            If (-not($ExcludeList.Contains($TmpAdmin.samAccountName))) {
                $ExcludeList.Add($TmpAdmin.samAccountName)
            } #end If

            # If the TheGood not exist, add it
            If (-not($ExcludeList.Contains('TheGood'))) {
                $ExcludeList.Add('TheGood')
            } #end If

            # If the TheUgly not exist, add it
            If (-not($ExcludeList.Contains('TheUgly'))) {
                $ExcludeList.Add('TheUgly')
            } #end If

            # If the krbtgt not exist, add it
            If (-not($ExcludeList.Contains('krbtgt'))) {
                $ExcludeList.Add('krbtgt')
            } #end If
        } #end If

        # Fetch all user accounts in the given OU
        try {
            $AllPrivUsers = Get-ADUser -Filter * -SearchBase $PsBoundParameters['AdminUsersDN'] -ErrorAction Stop
        } catch {
            Write-Error "Failed to retrieve users: $_"
            return
        } #end Try-Catch

        Write-Verbose ('Found {0} semi privileged accounts (_T0, _T1, _T2) in {1}' -f $AllPrivUsers.Count, $PsBoundParameters['AdminUsersDN'])

        # Get tiering groups
        $Tier0Group = Get-AdObjectType -Identity $PsBoundParameters['Tier0Group']

        If ($PsBoundParameters['Tier1Group']) {
            $Tier1Group = Get-AdObjectType -Identity $PsBoundParameters['Tier1Group']
        }
        If ($PsBoundParameters['Tier2Group']) {
            $Tier2Group = Get-AdObjectType -Identity $PsBoundParameters['Tier2Group']
        }

        [int]$T0 = 0
        [int]$T1 = 0
        [int]$T2 = 0
        [int]$i = 0

        # Define an empty array
        $T0Members = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $T1Members = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $T2Members = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    } #end Begin

    Process {
        # Get T0 Admin members
        Get-ADGroupMember -Identity $Tier0Group | ForEach-Object { $T0Members.Add($_.sAMAccountName) }

        # Get T1 Admin members
        If ($PsBoundParameters['Tier1Group']) {
            Get-ADGroupMember -Identity $Tier1Group | ForEach-Object { $T1Members.Add($_.sAMAccountName) }
        } #end If

        # Get T2 Admin members
        If ($PsBoundParameters['Tier2Group']) {
            Get-ADGroupMember -Identity $Tier2Group | ForEach-Object { $T2Members.Add($_.sAMAccountName) }
        } #end If

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

            if ($ExcludeList -notcontains $user.SamAccountName) {

                # Get last 3 characters of samAccountName which indicates tier
                $Last3Char = $user.SamAccountName -replace '.*(_T[0-2])$', '$1'

                switch ($Last3Char) {
                    '_T0' {
                        If ($T0Members -notcontains $user.SamAccountName -and $PSCmdlet.ShouldProcess($user.SamAccountName, 'Add to Tier0')) {
                            Add-ADGroupMember -Identity $Tier0Group -Members $user.SamAccountName
                            Write-Verbose ('Tier0 - {0}' -f $user.SamAccountName)
                            $T0 ++
                            $T0Members.Add($user.samAccountName)
                        } #end If
                    } #end _T0

                    '_T1' {
                        If ($T1Members -notcontains $user.SamAccountName -and $PSCmdlet.ShouldProcess($user.SamAccountName, 'Add to Tier1')) {
                            Add-ADGroupMember -Identity $Tier1Group -Members $user.SamAccountName
                            Write-Verbose ('Tier1 - {0}' -f $user.SamAccountName)
                            $T1 ++
                            $T1Members.Add($user.samAccountName)
                        } #end If
                    } #end _T1

                    '_T2' {
                        If ($T2Members -notcontains $user.SamAccountName -and $PSCmdlet.ShouldProcess($user.SamAccountName, 'Add to Tier2')) {
                            Add-ADGroupMember -Identity $Tier2Group -Members $user.SamAccountName
                            Write-Verbose ('Tier2 - {0}' -f $user.SamAccountName)
                            $T2 ++
                            $T2Members.Add($user.samAccountName)
                        } #end If
                    } #end _T2

                    default {
                        Write-Verbose ('{0} - To Be Removed from this OU' -f $user.SamAccountName)
                        If ($PsBoundParameters['DisableNonStandardUsers'] -and $PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable non-standard user')) {
                            Disable-ADAccount -Identity $user
                            Write-Verbose ('Account {0} was disabled due compliance.' -f $user.SamAccountName)
                        } #end If
                    } #end default
                } #end Switch
            } #end If
        } #end ForEach
    } #end Process

    End {
        $Constants.NL
        Write-Verbose 'Added new semi-privileged users'
        Write-Verbose '--------------------------------'
        Write-Verbose ('Admin Area   / Tier0: {0}' -f $T0)
        Write-Verbose ('Servers Area / Tier1: {0}' -f $T1)
        Write-Verbose ('Sites Area   / Tier2: {0}' -f $T2)
        $Constants.NL

        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished setting semi-privileged and/or Privileged users housekeeping."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
