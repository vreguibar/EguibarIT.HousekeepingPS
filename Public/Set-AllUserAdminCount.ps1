function Set-AllUserAdminCount {
    <#
        .SYNOPSIS
            Clears the 'adminCount' attribute and enables inherited security on all user objects with 'adminCount = 1' in a specified scope.

        .DESCRIPTION
            This function finds all user objects with 'adminCount = 1' in a specified Organizational Unit (OU) or in the entire domain
            and clears the 'adminCount' attribute while also enabling inherited security on those user objects.

        .PARAMETER SubTree
            Processes user objects with 'adminCount = 1' in a specified OU and its child OUs. If not specified, the entire domain is processed.

        .PARAMETER SearchRootDN
            The Distinguished Name of the OU where the search should begin. This parameter is required if using the SubTree parameter.

        .EXAMPLE
            Set-AllUserAdminCount

            Description
            -----------
            Clears the 'adminCount' attribute and resets inheritance on all user objects with 'adminCount = 1' in the domain.

        .EXAMPLE
            Set-AllUserAdminCount -SubTree -SearchRootDN "OU=Admin Accounts,OU=Admin,DC=EguibarIT,DC=local"

            Description
            -----------
            Clears the 'adminCount' attribute and resets inheritance on all user objects with 'adminCount = 1' in the specified OU.

        .OUTPUTS
            Integer
            Outputs the number of user objects modified.

        .NOTES
            Version:        1.1
            Author:         Vicente Rodriguez Eguibar
            Date:           08/Feb/2024
            Contact:        vicente@eguibar.com
            Company:        Eguibar Information Technology S.L.
            http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([int])]

    Param (
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'SubTree',
            HelpMessage = 'Process user objects within a specific OU and its child OUs.'
        )]
        [switch]$SubTree,

        [Parameter(
            Position = 1,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'SubTree',
            HelpMessage = 'The Distinguished Name of the OU where the search starts.'
        )]
        [string]
        $SearchRootDN,

        [Parameter(
            Position = 2,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'List of user SamAccountNames to exclude from processing (Administrator and krbtgt are already included).'
        )]
        [System.Collections.Generic.List[string]]
        $ExcludedUsers
    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Variables Definition

        $ObjectsChanged = 0
        # Initialize a generic list to store ADUser objects
        $UsersToProcess = [System.Collections.Generic.List[Microsoft.ActiveDirectory.Management.ADUser]]::New()

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # If parameter is parsed, initialize variable to be used by default objects
        If (-Not $PSBoundParameters.ContainsKey('ExcludedUsers')) {
            $ExcludedUsers = [System.Collections.Generic.List[string]]::New()
        } #end If

        $wellKnownUserSids = @{
            'S-1-5-21-*-500' = 'Administrator'
            'S-1-5-21-*-502' = 'krbtgt'
        }

        foreach ($sid in $wellKnownUserSids.Keys) {
            # For these SIDs, we always need to use the wildcard approach
            $users = Get-ADUser -Filter * | Where-Object -FilterScript { $_.SID -like $sid }

            foreach ($user in $users) {
                if ($user -and ($user.SamAccountName -notin $ExcludedUsers)) {
                    $ExcludedUsers.Add($user.SamAccountName)
                } #end If
            } #end Foreach
        } #end Foreach
    }

    Process {
        try {
            # Query AD for user objects with adminCount = 1
            $Splat.Clear()
            $Splat['Filter'] = 'adminCount -eq 1'
            $Splat['Properties'] = @('SamAccountName', 'DistinguishedName')

            if ($SubTree) {
                $Splat['SearchBase'] = $SearchRootDN
                $Splat['SearchScope'] = 'Subtree'
            }

            $users = Get-ADUser @Splat

            $totalUsers = $users.Count

            Write-Verbose -Message ('Total users found: {0}' -f $totalUsers)

            foreach ($user in $Users) {

                $Splat.Clear()
                $Splat['Activity'] = 'Processing Users'
                $Splat['Status'] = 'Processing {0} ({1} of {2})' -f $user.SamAccountName, ($users.IndexOf($user) + 1), $totalUsers
                $Splat['PercentComplete'] = (($users.IndexOf($user) + 1) / $totalUsers) * 100
                Write-Progress @Splat

                # Skip certain built-in accounts
                if ($User.SamAccountName -notin $ExcludedUsers) {

                    if ($PSCmdlet.ShouldProcess($User.DistinguishedName, 'Clear adminCount and reset inheritance')) {

                        $Result = Clear-AdminCount -SamAccountName $User.SamAccountName -Verbose:$VerbosePreference

                        if ($Result -like '*Updated*') {
                            $ObjectsChanged++
                            Write-Verbose -Message ('Updated user: {0}' -f $user.DistinguishedName)
                        } #end If
                    } #end If
                } else {
                    Write-Verbose -Message ('
                        [Skipped]
                            Excluded user: {0}
                            ' -f $user.SamAccountName
                    )
                }#end If
            } #end Foreach
        } catch {
            Write-Error -Message ('An error occurred: {0}' -f $_)
        } #end Try-Catch
    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'processing AdminCount on user objects.'
        )
        Write-Verbose -Message $txt

        return $ObjectsChanged
    } #end End
}
