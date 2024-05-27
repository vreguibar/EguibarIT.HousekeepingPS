function Set-NonPrivilegedGroupHousekeeping {
    <#
        .Synopsis
            Removes non-privileged groups from semi-privileged user accounts within a specified OU.

        .DESCRIPTION
            This function enumerates and evaluates all groups to which each user in a specified
            OU belongs. If any of the groups are outside of the designated 'Admin Area' or
            'BuiltIn' containers, the user is removed from those groups.

        .EXAMPLE
            Set-NonPrivilegedGroupHousekeeping "OU=Users,OU=Admin,DC=EguibarIT,DC=local"

        .EXAMPLE
            Set-NonPrivilegedGroupHousekeeping -AdminUsersDN "OU=Users,OU=Admin,DC=EguibarIT,DC=local

        .PARAMETER AdminUsersDN
            Admin User Account OU Distinguished Name (ej. "OU=Users,OU=Admin,DC=EguibarIT,DC=local").

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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]

    Param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin User Account OU Distinguished Name (ej. "OU=Users,OU=Admin,DC=EguibarIT,DC=local").',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $AdminUsersDN
    )

    Begin {
        Write-Verbose -Message '|=> ************************************************************************ <=|'
        Write-Verbose -Message (Get-Date).ToShortDateString()
        Write-Verbose -Message ('  Starting: {0}' -f $MyInvocation.Mycommand)
        Write-Verbose -Message ('Parameters used by the function... {0}' -f (Get-FunctionDisplay $PsBoundParameters -Verbose:$False))

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        # Get all semi-privileged users from Admin Area
        $AllAdmin = Get-ADUser -Filter * -Properties SamAccountName, MemberOf -SearchBase ($PSBoundParameters['AdminUsersDN'])

        $Constants.NL
        Write-Verbose ('Found {0} semi privileged accounts (_T0, _T1, _T2)' -f $AllAdmin.Count)

        $i = 0
    } #end Begin

    Process {

        # Iterate through all semi-privileged users
        Foreach ($admin in $allAdmin) {

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
                if (-not($group.Contains('OU=ADMINISTRATION,{0}' -f $Variables.AdDn) -or $group.Contains('CN=Builtin,{0}' -f $Variables.AdDn))) {

                    # Remove the user from the non-privileged group.
                    if ($PSCmdlet.ShouldProcess("$($adminUser.SamAccountName) in $group", 'Remove from group')) {

                        Remove-ADGroupMember -Identity $Group -Members $admin.SamAccountName -Confirm:$False
                        Write-Verbose -Message ('Semi-Privileged user {0} was removed from non-privileged group {1}' -f $admin.SamAccountName, $Group)

                    } #end If

                } #end If

            } #end Foreach

        } #end Foreach

    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished removing Semi-Privileged user from non-compliant groups.."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
