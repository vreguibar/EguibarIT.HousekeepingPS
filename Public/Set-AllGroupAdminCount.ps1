function Set-AllGroupAdminCount {
    <#
        .SYNOPSIS
            Clears the 'adminCount' attribute and enables inherited security on all group objects with 'adminCount = 1' in a specified scope.

        .DESCRIPTION
            This function finds all group objects with 'adminCount = 1' in a specified Organizational Unit (OU) or in the entire domain
            and clears the 'adminCount' attribute while also enabling inherited security on those group objects.

        .PARAMETER SubTree
            Processes group objects with 'adminCount = 1' in a specified OU and its child OUs. If not specified, the entire domain is processed.

        .PARAMETER SearchRootDN
            The Distinguished Name of the OU where the search should begin. This parameter is required if using the SubTree parameter.

        .PARAMETER ExcludedGroups
            A list of group SamAccountNames to exclude from processing.

        .EXAMPLE
            Set-AllGroupAdminCount

            Description
            -----------
            Clears the 'adminCount' attribute and resets inheritance on all group objects with 'adminCount = 1' in the domain.

        .EXAMPLE
            Set-AllGroupAdminCount -SubTree -SearchRootDN "OU=Admin Groups,OU=Admin,DC=EguibarIT,DC=local" -ExcludedGroups "Domain Admins", "Enterprise Admins"

            Description
            -----------
            Clears the 'adminCount' attribute and resets inheritance on all group objects with 'adminCount = 1' in the specified OU, excluding the specified groups.

        .OUTPUTS
            Integer
            Outputs the number of group objects modified.

        .NOTES
            Version:        1.0
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
            HelpMessage = 'Process group objects within a specific OU and its child OUs.'
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
            HelpMessage = 'List of group SamAccountNames to exclude from processing.'
        )]
        [System.Collections.Generic.List[string]]
        $ExcludedGroups
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

        # Initialize ExcludedGroups if not provided
        if (-not $PSBoundParameters.ContainsKey('ExcludedGroups')) {
            $ExcludedGroups = [System.Collections.Generic.List[string]]::new()
        } #end If

        # Initialize splatting hashtables
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        $wellKnownSids = @{
            'S-1-5-32-544'   = 'Administrators'
            'S-1-5-32-548'   = 'Account Operators'
            'S-1-5-32-549'   = 'Server Operators'
            'S-1-5-32-550'   = 'Print Operators'
            'S-1-5-32-552'   = 'Replicators'
            'S-1-5-21-*-512' = 'Domain Admins'
            'S-1-5-21-*-516' = 'Domain Controllers'
            'S-1-5-21-*-518' = 'Schema Admins'
            'S-1-5-21-*-519' = 'Enterprise Admins'
            'S-1-5-21-*-521' = 'Read-only Domain Controllers'
            'S-1-5-21-*-526' = 'Key Admins'
            'S-1-5-21-*-527' = 'Enterprise Key Admins'
        }

        # iterate all default groups (Default AdminCount = 1)
        foreach ($sid in $wellKnownSids.Keys) {
            if ($sid -like '*-*-*') {
                # For SIDs with wildcards, we need to use a different approach
                $groups = Get-ADGroup -Filter * | Where-Object -FilterScript { $_.SID -like $sid }
            } else {
                $Splat['Filter'] = 'SID -eq ''{0}''' -f $sid
                $groups = Get-ADGroup @Splat
            } #end If-Else

            # Ensure default exclusions are added to variable
            foreach ($group in $groups) {
                if ($group -and ($group.SamAccountName -notin $ExcludedGroups)) {
                    $ExcludedGroups.Add($group.SamAccountName)
                } #end If
            } #end ForEach
        } #end ForEach

    } #end Begin

    Process {
        try {
            $Splat.Clear()
            $Splat['Filter'] = 'adminCount -eq 1'
            $Splat['Properties'] = @('SamAccountName', 'DistinguishedName')

            if ($SubTree) {
                $Splat['SearchBase'] = $SearchRootDN
                $Splat['SearchScope'] = 'Subtree'
            }

            $groups = Get-ADGroup @Splat
            $totalGroups = $groups.Count
            Write-Verbose -Message ('Total groups found: {0}' -f $totalGroups)

            foreach ($Group in $Groups) {

                $Splat.Clear()
                $Splat['Activity'] = 'Processing Groups'
                $Splat['Status'] = 'Processing {0} ({1} of {2})' -f $group.SamAccountName, ($groups.IndexOf($group) + 1), $totalGroups
                $Splat['PercentComplete'] = (($groups.IndexOf($group) + 1) / $totalGroups) * 100
                Write-Progress @Splat

                # Skip excluded groups
                if ($Group.SamAccountName -notin $ExcludedGroups) {

                    if ($PSCmdlet.ShouldProcess($Group.DistinguishedName, 'Clear adminCount and reset inheritance')) {

                        $Result = Clear-AdminCount -SamAccountName $Group.SamAccountName -Verbose:$VerbosePreference

                        if ($Result -like '*Updated*') {
                            $ObjectsChanged++
                            Write-Verbose -Message ('Updated group: {0}' -f $group.DistinguishedName)
                        } #end If
                    } #end If
                } else {
                    Write-Verbose -Message ('
                        [Skipped]
                            Excluded group: {0}
                            ' -f $group.SamAccountName
                    )
                }#end If
            } #end Foreach
        } catch {
            Write-Error -Message ('An error occurred: {0}' -f $_)
        } #end Try-Catch
    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'processing AdminCount on group objects.'
        )
        Write-Verbose -Message $txt

        return $ObjectsChanged
    } #end End
}
