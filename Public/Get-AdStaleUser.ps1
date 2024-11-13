function Get-AdStaleUser {

    <#
        .SYNOPSIS
            Finds stale users by last logon date offset.

        .DESCRIPTION
            This function queries Active Directory to find user accounts that have not logged on within a specified offset in days.

        .PARAMETER DaysOffset
            Specifies the time span in days to define the stale period.

        .PARAMETER SearchBase
            Optional. Specifies the distinguished name of an Active Directory container to search within (e.g., "OU=Users,DC=EguibarIT,DC=local").

        .EXAMPLE
            Get-AdStaleUser -DaysOffset 90

        .EXAMPLE
            Get-AdStaleUser -DaysOffset 90 -SearchBase "OU=Users,DC=EguibarIT,DC=local"

        .EXAMPLE
            $Splat = @{
                DaysOffset = 90
                SearchBase = "OU=Users,DC=EguibarIT,DC=local"
                Verbose    = $true
            }
            Get-AdStaleUser @Splat

        .INPUTS
            Int32: Number of days to use as the offset for the last logon check.

        .OUTPUTS
            List of objects System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADUser]

        .NOTES
            Version:         1.0
            DateModified:    13/Nov/2024
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com

        .NOTES
            Cmdlets used:
                Name                      | Module
                --------------------------|--------------------------
                Get-ADUser                | ActiveDirectory
                Write-Verbose             | Microsoft.PowerShell.Utility
                Write-Error               | Microsoft.PowerShell.Utility
                Write-Output              | Microsoft.PowerShell.Utility
                Get-Date                  | Microsoft.PowerShell.Utility
                Import-MyModule           | EguibarIT & EguibarIT.DelegationPS

    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([Microsoft.ActiveDirectory.Management.ADUser[]])]


    Param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Integer representing the amount of days of searching.',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [int]
        $DaysOffset,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Distinguished Name for the search base (OU or container).',
            Position = 1)]
        [AllowNull()]
        [string]
        $SearchBase

    )

    begin {
        # Enable strict mode for variable declaration and usage
        Set-StrictMode -Version Latest

        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        Import-MyModule ActiveDirectory -ErrorAction Stop

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Define return type as HashSet for unique stale users
        $StaleUsers = [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADUser]]::new([StringComparer]::OrdinalIgnoreCase)

        # Calculate the date threshold based on the DaysOffset parameter
        $ThresholdDate = (Get-Date).AddDays(-$DaysOffset)
        Write-Verbose -Message (
            'Searching for users with last logon date earlier than {0}' -f
            $ThresholdDate.ToUniversalTime()
        )

    } # end begin

    process {

        # Ensure that ShouldProcess is confirmed before proceeding with search
        if ($PSCmdlet.ShouldProcess('Active Directory', "Find users with no logon within the last $DaysOffset days")) {
            try {

                # Retrieve all user accounts from AD
                # This filter retrieves only users whose LastLogonTimestamp is older than $ThresholdDate
                # or is unset, indicating they may never have logged on.
                $Splat = @{
                    Filter   = "(LastLogonTimestamp -lt '$($ThresholdDate.ToFileTime())' -or !LastLogonTimestamp)"
                    Property = 'LastLogon', 'LastLogonTimestamp'
                }
                if ($SearchBase) {
                    $Splat['SearchBase'] = $SearchBase
                } #end If

                # Retrieve all users from Active Directory
                $Users = Get-ADUser @Splat

                foreach ($User in $Users) {
                    # Convert LastLogon and LastLogonTimestamp to DateTime, defaulting to the oldest available date
                    $LastLogonDate = if ($User.LastLogon) {
                        [DateTime]::FromFileTime([int64]$User.LastLogon)
                    } else {
                        [DateTime]::MaxValue
                    } #end If-Else

                    $LastLogonTimestampDate = if ($User.LastLogonTimestamp) {
                        [DateTime]::FromFileTime([int64]$User.LastLogonTimestamp)
                    } else {
                        [DateTime]::MaxValue
                    } #end If-Else

                    # Determine the earlier logon date for staleness comparison
                    $EffectiveLastLogon = if ($LastLogonDate -le $LastLogonTimestampDate) {
                        $LastLogonDate
                    } else {
                        $LastLogonTimestampDate
                    } #end If-Else

                    # Check if the effective last logon date is earlier than the threshold
                    if ($EffectiveLastLogon -le $ThresholdDate) {
                        Write-Verbose -Message (
                            'User {0} with effective
                        last logon date of {1}
                        added to stale users.' -f
                            $User.SamAccountName, $EffectiveLastLogon
                        )
                        $StaleUsers.Add($User) | Out-Null
                    } # end if
                } # end foreach
            } # end try
            catch {
                Write-Error -Message ('Error retrieving users: {0}' -f $_.Exception.Message)
            } # end catch
        } #end If
    } # end process

    end {
        # Return the list of stale users
        if ($StaleUsers.Count -gt 0) {
            Write-Output $StaleUsers
        } else {
            Write-Output ('No stale users found within the specified offset of {0} days.' -f $DaysOffset)
        }
    } # end end
} # end function
