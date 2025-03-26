Function Get-AdStaleComputer {

    <#
        .SYNOPSIS
            Find staled computers by Last Logon date offset.

        .DESCRIPTION
            This function queries Active Directory for computers that have not logged on for a specified number of days.
            It uses the LastLogonTimestamp attribute to determine whether a computer is stale.

        .PARAMETER DaysOffset
            The number of days to calculate the offset for finding stale computers (int).

        .EXAMPLE
            Find-StaleComputers -DaysOffset 90

            This will return all computers that have not logged on in the last 90 days.

        .INPUTS
            Int32 - DaysOffset, which is the time span in days to determine stale computers.

        .OUTPUTS
            A list of computer objects from Active Directory which are considered stale based on the DaysOffset.

        .NOTES
            Version:         1.4
            DateModified:    12/Nov/2024
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com

        .NOTES
            Cmdlets used:
                Name                      | Module
                --------------------------|--------------------------
                Get-ADComputer            | ActiveDirectory
                Write-Verbose             | Microsoft.PowerShell.Utility
                Write-Warning             | Microsoft.PowerShell.Utility
                Write-Error               | Microsoft.PowerShell.Utility
                Write-Output              | Microsoft.PowerShell.Utility
                Get-Date                  | Microsoft.PowerShell.Utility
                Import-MyModule           | EguibarIT & EguibarIT.DelegationPS

    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'low')]
    [OutputType([System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADComputer]])]

    param (

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
            HelpMessage = 'Distinguished Name where the search will start from.',
            Position = 1)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $SearchBase

    )

    Begin {
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

        # Calculate the time offset
        $timeStamp = (Get-Date).AddDays(-$DaysOffset).ToFileTime()
        Write-Verbose -Message ('TimeStamp for stale computers: {0}' -f $timeStamp)

        # Initialize an empty list to hold stale computers
        $StaleComputers = [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADComputer]]::new()

    } #end Begin

    Process {

        # Ensure that ShouldProcess is confirmed before proceeding with search
        if ($PSCmdlet.ShouldProcess('Active Directory', "Find computers with no logon within the last $DaysOffset days")) {
            try {
                # Prepare the Get-ADComputer parameters
                $Splat = @{
                    Filter     = "LastLogonTimestamp -lt $timeStamp -or LastLogonTimestamp -notlike '*'"
                    Properties = 'LastLogonTimestamp'
                }

                if ($SearchBase) {
                    $Splat['SearchBase'] = $SearchBase
                }

                # Retrieve all computers from Active Directory
                $computers = Get-ADComputer @Splat

                # Iterate over each computer and check if it is stale
                foreach ($computer in $computers) {

                    if ($null -ne $computer.LastLogonTimestamp) {

                        # Convert the LastLogonTimestamp from AD to a readable format
                        $lastLogon = [DateTime]::FromFileTime([Int64]$computer.LastLogonTimestamp)

                        Write-Verbose -Message (
                            '{0} last logon time: {1}' -f
                            $computer.Name,
                            $lastLogon.ToString('yyyy-MM-dd HH:mm:ss')
                        )

                        # Check if the last logon is older than the threshold
                        if ($lastLogon -le $timeStamp) {

                            Write-Warning -Message ('{0} is stale.' -f $computer.Name)
                            [void]$StaleComputers.Add($computer)

                        } #end if
                    } else {
                        Write-Warning -Message ('{0} has never logged on.' -f $computer.Name)
                    } #end if-else
                } #end foreach
            } catch {
                Write-Error -Message ('An error occurred while retrieving computers: {0}' -f $_)
            } #end Try-Catch
        } #end If
    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'getting stale computers.'
        )
        Write-Verbose -Message $txt

        # Return the list of stale computers
        if ($StaleComputers.Count -gt 0) {
            Write-Output $StaleComputers
        } else {
            Write-Verbose -Message 'No stale computers found based on the provided DaysOffset.'
        }
    } #end End

} #end function
