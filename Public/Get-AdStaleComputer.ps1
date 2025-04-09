Function Get-AdStaleComputer {

    <#
        .SYNOPSIS
            Identifies computers in Active Directory that haven't logged on for a specified period.

        .DESCRIPTION
            Searches Active Directory for computer objects that haven't logged on within a specified
            number of days. Uses efficient LDAP filtering and supports searching within specific OUs.
            The function provides detailed logging and supports credential delegation.

        .PARAMETER DaysOffset
            Number of days to look back for the last logon. Default is 60 days.

        .PARAMETER SearchBase
            Distinguished Name of the OU to start the search from. If not specified, searches entire domain.

        .PARAMETER DomainController
            Specifies the domain controller to query. If not specified, uses the default DC.

        .OUTPUTS
            [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADComputer]]
            Collection of stale computer objects with properties:
                Name: Computer name
                DistinguishedName: AD path
                LastLogonTimestamp: Last logon time
                Enabled: Account status
                Created: Creation date

        .EXAMPLE
            Get-AdStaleComputer -DaysOffset 90
            Finds computers that haven't logged on in 90 days.

        .NOTES
            Used Functions:
                Name                                   ║ Module
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ADComputer                         ║ ActiveDirectory
                Write-Progress                         ║ Microsoft.PowerShell.Utility
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Warning                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS
                Import-MyModule                        ║ EguibarIT.HousekeepingPS
                Test-IsValidDN                         ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.7
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
    [OutputType([System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADComputer]])]

    param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Integer representing the amount of days of searching.',
            Position = 0)]
        [ValidateRange(1, 3650)]
        [PSDefaultValue(Help = 'Default Value is "60"',
            Value = 60
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
            HelpMessage = 'Domain Controller to use.',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('DC')]
        [string]
        $DomainController

    )

    Begin {
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

        Import-MyModule ActiveDirectory -ErrorAction Stop

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        [hashtable]$ADParams = @{
            ErrorAction = 'Stop'
            Properties  = @('LastLogonTimestamp', 'Created', 'Enabled', 'Description')
        }

        # Add optional parameters
        if ($PSBoundParameters.ContainsKey('DomainController')) {
            $ADParams['Server'] = $DomainController
        } #end If
        if ($PSBoundParameters.ContainsKey('SearchBase')) {
            $ADParams['SearchBase'] = $SearchBase
        } #end If

        # Calculate the time offset
        $timeStamp = (Get-Date).AddDays(-$DaysOffset).ToFileTime()
        Write-Verbose -Message ('TimeStamp for stale computers: {0}' -f $timeStamp)

        # Initialize an empty list to hold stale computers
        $StaleComputers = [System.Collections.Generic.HashSet[Microsoft.ActiveDirectory.Management.ADComputer]]::new()

    } #end Begin

    Process {

        if ($PSCmdlet.ShouldProcess('Active Directory', "Find computers with no logon within the last $DaysOffset days")) {

            try {
                Write-Progress -Activity 'Searching for Stale Computers' -Status 'Querying Active Directory...' -PercentComplete 0

                # Optimize LDAP filter for better performance
                $ADParams['Filter'] = {
                    (LastLogonTimestamp -lt $timeStamp) -or
                    (LastLogonTimestamp -notlike '*' -and Created -lt $timeStamp)
                }

                # Get computers and process in batches
                $computers = Get-ADComputer @ADParams
                $total = $computers.Count
                $current = 0
                $batchCount = [Math]::Ceiling($total / $BatchSize)

                Write-Verbose -Message ('Found {0} computers to process in {1} batches' -f $total, $batchCount)

                foreach ($computer in $computers) {

                    $current++
                    $Splat = @{
                        Activity        = 'Processing Stale Computers'
                        Status          = "Processing $($computer.Name) ($current of $total)"
                        PercentComplete = (($current / $total) * 100)
                    }
                    Write-Progress @Splat

                    if ($null -ne $computer.LastLogonTimestamp) {

                        $lastLogon = [DateTime]::FromFileTime([Int64]$computer.LastLogonTimestamp)
                        Write-Verbose -Message ('{0} last logon: {1}' -f $computer.Name,
                            $lastLogon.ToString('yyyy-MM-dd HH:mm:ss'))

                        if ($lastLogon -le [DateTime]::FromFileTime($timeStamp)) {

                            [void]$StaleComputers.Add($computer)
                            Write-Warning -Message ('{0} is stale - Last logon: {1}' -f $computer.Name, $lastLogon)

                        } #end If

                    } else {

                        [void]$StaleComputers.Add($computer)
                        Write-Warning -Message ('{0} has never logged on - Created: {1}' -f $computer.Name,
                            $computer.Created)

                    } #end If-else
                } #end foreach

            } catch {

                $errorMsg = 'Error retrieving stale computers: {0}' -f $_.Exception.Message
                Write-Error -Message $errorMsg
                throw $_.Exception

            } finally {

                Write-Progress -Activity 'Processing Stale Computers' -Completed

            } #end Try/Catch/Finally

        } #end If

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'getting stale computers.'
            )
            Write-Verbose -Message $txt
        } #end If

        # Return the list of stale computers
        if ($StaleComputers.Count -gt 0) {
            Write-Output $StaleComputers
        } else {
            Write-Verbose -Message 'No stale computers found based on the provided DaysOffset.'
        } #end If-else
    } #end End

} #end function Get-AdStaleComputer
