function Set-NonPrivilegedGroupHousekeeping {
    <#
        .Synopsis
            Removes non-privileged groups from semi-privileged user accounts within a specified OU.

        .DESCRIPTION
            This function enumerates and evaluates all groups to which each user in a specified
            OU belongs. If any of the groups are outside of the designated 'Admin Area' or
            'BuiltIn' containers, the user is removed from those groups.

        .PARAMETER AdminUsersDN
            Admin User Account OU Distinguished Name (e.g., "OU=Users,OU=Admin,DC=EguibarIT,DC=local").

        .PARAMETER Tier0RootOuDN
            Tier0 Root OU Distinguished Name (e.g., "OU=Admin,DC=EguibarIT,DC=local").

        .EXAMPLE
            Set-NonPrivilegedGroupHousekeeping "OU=Users,OU=Admin,DC=EguibarIT,DC=local" "OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-NonPrivilegedGroupHousekeeping -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local" -Tier0RootOuDN "OU=Admin,DC=EguibarIT,DC=local"

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADUser                             | ActiveDirectory
                Remove-ADGroupMember                   | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Progress                         | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    10/Nov/2017
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([void])]

    Param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin User Account OU Distinguished Name (ej. "OU=Users,OU=Admin,DC=EguibarIT,DC=local").',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminUsersDN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Tier0 root OU Distinguished Name (ej. "OU=Admin,DC=EguibarIT,DC=local").',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('RootOU', 'Admin', 'AdminArea')]
        [String]
        $Tier0RootOuDN

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

        Import-MyModule ActiveDirectory -Force -Verbose:$false

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Get all semi-privileged users from Admin Area
        try {
            $Splat = @{
                Filter     = '*'
                Properties = 'SamAccountName', 'MemberOf'
                SearchBase = $PSBoundParameters['AdminUsersDN']
            }
            $AllAdmin = Get-ADUser @Splat
        } catch {
            Write-Error -Message ('Error retrieving users from OU: {0}' -f $_)
            return
        } #end Try-catch

        Write-Verbose -Message ('Found {0} semi privileged accounts (_T0, _T1, _T2)' -f $AllAdmin.Count)

        # Initialize counter
        [int]$i = 0

    } #end Begin

    Process {

        # Iterate through all semi-privileged users
        Foreach ($admin in $allAdmin) {
            $i++

            # Display the progress bar
            $Splat = @{
                Activity        = 'Checking Semi-Privileged Users'
                Status          = ('Working on item No. {0} from {1}' -f $i, $allAdmin.Count)
                PercentComplete = ($i / $allAdmin.Count * 100)
            }
            Write-Progress @Splat

            # Iterate through the list of groups of the current user
            Foreach ($Group in $admin.MemberOf) {

                # Check the distinguished name of the group. If not part of Admin area and/or BuiltIn continue
                if (-not (
                        ($Group -match $PSBoundParameters['Tier0RootOuDN']) -or
                        ($Group -match 'CN=Builtin')
                    )) {

                    # Remove the user from the non-privileged group.
                    if ($PSCmdlet.ShouldProcess("$($adminUser.SamAccountName) in $group", 'Remove from group')) {

                        try {

                            $Splat = @{
                                Identity = $Group
                                Members  = $admin.SamAccountName
                                Confirm  = $False
                            }
                            Remove-ADGroupMember @Splat

                            Write-Verbose -Message ('
                                Semi-Privileged user {0}
                                was removed from non-privileged group {1}' -f
                                $admin.SamAccountName, $Group
                            )

                        } catch {
                            Write-Error -Message ('
                                Error removing {0}
                                from group {1}: {2}' -f
                                $admin.SamAccountName, $Group, $_
                            )
                        } #end Try-catch

                    } #end If

                } #end If

            } #end Foreach

        } #end Foreach

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing Semi-Privileged user from non-compliant groups'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end End
} #end Function Set-NonPrivilegedGroupHousekeeping
