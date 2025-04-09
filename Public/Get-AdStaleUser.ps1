function Get-AdStaleUser {

    <#
        .SYNOPSIS
            Identifies user accounts in Active Directory that haven't logged on for a specified period.

        .DESCRIPTION
            Searches Active Directory for user accounts that haven't logged on within a specified
            number of days. Uses efficient LDAP filtering and supports searching within specific OUs.
            The function provides detailed logging and supports credential delegation.

        .PARAMETER DaysOffset
            Number of days to look back for the last logon. Default is 90 days.
            Valid range: 1-3650 days.

        .PARAMETER SearchBase
            Distinguished Name of the OU to start the search from. If not specified, searches entire domain.

        .PARAMETER DomainController
            Specifies the domain controller to query. If not specified, uses the default DC.

        .PARAMETER Credential
            Specifies alternate credentials for the operation.

        .PARAMETER BatchSize
            Number of objects to process in each batch. Default is 1000.
            Valid range: 100-5000.

        .OUTPUTS
            [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADUser]]
            Collection of stale user objects with properties:
                Name: User name
                SamAccountName: Account name
                DistinguishedName: AD path
                LastLogon: Last logon time
                LastLogonTimestamp: Last logon timestamp
                EffectiveLastLogon: Earlier of LastLogon/LastLogonTimestamp
                Enabled: Account status
                Created: Creation date

        .EXAMPLE
            Get-AdStaleUser -DaysOffset 90
            Finds users that haven't logged on in 90 days.

        .EXAMPLE
            Get-AdStaleUser -DaysOffset 90 -SearchBase "OU=Users,DC=contoso,DC=com" -Credential (Get-Credential)
            Finds stale users in specific OU using alternate credentials.

        .NOTES
            Used Functions:
                Name                                   ║ Module
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ADUser                             ║ ActiveDirectory
                Write-Progress                         ║ Microsoft.PowerShell.Utility
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Warning                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS
                Import-MyModule                        ║ EguibarIT.HousekeepingPS
                Test-IsValidDN                         ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.1
            DateModified:    08/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Default'
    )]
    [OutputType([System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADUser]])]


    Param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Integer representing the amount of days of searching.',
            Position = 0)]
        [ValidateRange(1, 3650)]
        [PSDefaultValue(Help = 'Default Value is "90"',
            Value = 90
        )]
        [Alias('Days', 'Age')]
        [int]
        $DaysOffset,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Distinguished Name where the search will start from.',
            Position = 1)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $SearchBase,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Domain controller to use.',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('DC')]
        [string]$DomainController

    )

    begin {
        Set-StrictMode -Version Latest

        # Initialize logging
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports

        Import-MyModule ActiveDirectory -Verbose:$false

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        [hashtable]$ADParams = @{
            ErrorAction = 'Stop'
            Properties  = @(
                'Name',
                'SamAccountName',
                'LastLogon',
                'LastLogonTimestamp',
                'Enabled',
                'Created',
                'Description'
            )
        }

        # Add optional parameters
        if ($PSBoundParameters.ContainsKey('DomainController')) {
            $ADParams['Server'] = $DomainController
        } #end If

        # Define return type as HashSet for unique stale users
        $StaleUsers = [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADUser]]::new()

        # Calculate the date threshold based on the DaysOffset parameter
        $ThresholdDate = (Get-Date).AddDays(-$DaysOffset)
        $ThresholdFileTime = $ThresholdDate.ToFileTime()
        Write-Verbose -Message ('Cutoff timestamp for stale users: {0}' -f $ThresholdDate.ToString('yyyy-MM-dd HH:mm:ss'))

    } # end begin

    process {

        if ($PSCmdlet.ShouldProcess('Active Directory', "Find users with no logon within the last $DaysOffset days")) {

            try {
                Write-Progress -Activity 'Searching for Stale Users' -Status 'Querying Active Directory...' -PercentComplete 0

                # Optimize LDAP filter for better performance
                $ADParams['Filter'] = {
                    (LastLogonTimestamp -lt $ThresholdFileTime) -or
                    (LastLogonTimestamp -notlike '*' -and Created -lt $ThresholdFileTime)
                }

                # Get users and process in batches
                $users = Get-ADUser @ADParams
                $total = $users.Count
                $current = 0

                Write-Verbose -Message ('Found {0} users to process' -f $total)

                foreach ($user in $users) {

                    $current++
                    $Splat = @{
                        Activity        = 'Processing Stale Users'
                        Status          = "Processing $($user.SamAccountName) ($current of $total)"
                        PercentComplete = (($current / $total) * 100)
                    }
                    Write-Progress @Splat

                    try {

                        # Convert LastLogon and LastLogonTimestamp to DateTime
                        $LastLogonDate = if ($user.LastLogon) {
                            [DateTime]::FromFileTime([int64]$user.LastLogon)
                        } else {
                            [DateTime]::MinValue
                        } #end If-else

                        $LastLogonTimestampDate = if ($user.LastLogonTimestamp) {
                            [DateTime]::FromFileTime([int64]$user.LastLogonTimestamp)
                        } else {
                            [DateTime]::MinValue
                        } #end If-else

                        # Determine effective last logon date
                        $EffectiveLastLogon = if ($LastLogonDate -le $LastLogonTimestampDate) {
                            $LastLogonDate
                        } else {
                            $LastLogonTimestampDate
                        } #end If-else

                        # Add extended properties to user object
                        $user | Add-Member -NotePropertyName 'EffectiveLastLogon' -NotePropertyValue $EffectiveLastLogon -Force
                        $user | Add-Member -NotePropertyName 'DaysInactive' -NotePropertyValue ((Get-Date) - $EffectiveLastLogon).Days -Force

                        if ($EffectiveLastLogon -le $ThresholdDate) {

                            [void]$StaleUsers.Add($user)

                            Write-Warning -Message ('User {0} is stale - Last activity: {1} ({2} days)' -f
                                $user.SamAccountName,
                                $EffectiveLastLogon.ToString('yyyy-MM-dd HH:mm:ss'),
                                $user.DaysInactive)
                        } #end If

                    } catch {

                        Write-Error -Message ('Error processing user {0}: {1}' -f $user.SamAccountName, $_.Exception.Message)
                        continue

                    } #end Try/Catch
                } #end foreach

            } catch {

                Write-Error -Message ('Error retrieving users: {0}' -f $_.Exception.Message)
                throw

            } finally {

                Write-Progress -Activity 'Processing Stale Users' -Completed

            } #end Try/Catch/Finally

        } #end If ShouldProcess

    } # end process

    end {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'getting stale users.'
            )
            Write-Verbose -Message $txt
        } #end If

        # Return the list of stale users
        if ($StaleUsers.Count -gt 0) {
            Write-Output $StaleUsers
        } else {
            Write-Output ('No stale users found within the specified offset of {0} days.' -f $DaysOffset)
        }
    } # end end
} # end function Get-AdStaleUser
