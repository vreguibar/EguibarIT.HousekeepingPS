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

        .PARAMETER ExcludedUsers
            List of user SamAccountNames to exclude from processing. Built-in accounts like Administrator and krbtgt are automatically excluded.

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

        .INPUTS
            [System.String]
            [System.Collections.Generic.List[string]]

        .OUTPUTS
            [System.Int32]
            Returns the number of user objects modified.

        .NOTES
            Used Functions:
                Name                    ║ Module/Namespace
                ════════════════════════╬══════════════════════════════
                Get-ADUser              ║ ActiveDirectory
                Clear-AdminCount        ║ EguibarIT.HousekeepingPS
                Test-IsValidDN          ║ EguibarIT.HousekeepingPS
                Import-MyModule         ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:        1.2
            DateModified:    11/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT

        .COMPONENT
            Active Directory

        .ROLE
            Administrator

        .FUNCTIONALITY
            User Management
            Security Management
            AdminCount Cleanup
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Default'
    )]
    [OutputType([int])]

    Param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Process group objects within a specific OU and its child OUs.',
            Position = 0,
            ParameterSetName = 'SubTree')]
        [switch]
        $SubTree,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'The Distinguished Name of the OU where the search starts.',
            Position = 1,
            ParameterSetName = 'SubTree')]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $SearchRootDN,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'List of group SamAccountNames to exclude from processing.',
            Position = 2)]
        [ValidateNotNull()]
        [System.Collections.Generic.List[string]]
        $ExcludedGroups
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

        Import-MyModule -Name ActiveDirectory -Verbose:$false

        ##############################
        # Variables Definition

        [int]$ObjectsChanged = 0

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

            $Splat.Clear()
            $Splat['LDAPFilter'] = "(objectSid=*$sid)"
            $Splat['Properties'] = @('SamAccountName')

            $users = Get-ADUser @Splat

            foreach ($user in $users) {

                if ($user -and ($user.SamAccountName -notin $ExcludedUsers)) {
                    $ExcludedUsers.Add($user.SamAccountName)
                    Write-Verbose -Message ('Added well-known account to exclusion list: {0}' -f $user.SamAccountName)

                } #end If

            } #end Foreach

        } #end Foreach

    } #end Begin

    Process {
        try {
            # Query AD for user objects with adminCount = 1
            $Splat.Clear()
            $Splat['Filter'] = 'adminCount -eq 1'
            $Splat['Properties'] = @('SamAccountName', 'DistinguishedName')

            if ($SubTree) {
                $Splat['SearchBase'] = $SearchRootDN
                $Splat['SearchScope'] = 'Subtree'
            } #end If

            $users = Get-ADUser @Splat

            $totalUsers = $users.Count

            Write-Verbose -Message ('Total users found with adminCount=1: {0}' -f $totalUsers)

            foreach ($user in $Users) {

                $currentIndex = $users.IndexOf($user) + 1

                $Splat.Clear()
                $Splat['Activity'] = 'Processing Users'
                $Splat['Status'] = 'Processing {0} ({1} of {2})' -f $user.SamAccountName, $currentIndex, $totalUsers
                $Splat['PercentComplete'] = ($currentIndex / $totalUsers) * 100
                Write-Progress @Splat

                # Skip certain built-in accounts
                if ($User.SamAccountName -notin $ExcludedUsers) {

                    if ($PSCmdlet.ShouldProcess(
                            $User.DistinguishedName,
                            'Clear adminCount and reset inheritance'
                        )) {

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

                } #end If-else

            } #end Foreach

        } catch [System.ArgumentException] {

            Write-Error -Message $_.Exception.Message

        } catch {

            Write-Error -Message ('An unexpected error occurred: {0}' -f $_.Exception.Message)

        } #end Try-Catch

    } #end Process

    End {
        Write-Progress -Activity 'Processing Users' -Completed

        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'processing AdminCount on user objects.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $ObjectsChanged
    } #end End
} #end Function Set-AllUserAdminCount
