Function Set-PrivilegedComputerHousekeeping {
    <#
        .SYNOPSIS
            Manages privileged and semi-privileged computers (PAWs and Infrastructure Servers) by updating their group memberships.

        .DESCRIPTION
            This function identifies privileged (PAWs) and infrastructure servers from a specified Organizational Unit (OU) in Active Directory
            and ensures their correct group memberships. It assigns computers running server operating systems to the infrastructure servers group
            and other machines to the PAW group. This operation helps to automate the housekeeping of privileged computers, ensuring they are
            consistently and correctly managed according to their roles.

        .PARAMETER SearchRootDN
            Specifies the distinguished name (DN) of the OU where the function will search for computers. Only computers under this
            search base will be processed.

        .PARAMETER InfraGroup
            Specifies the distinguished name or group identifier for the group that contains all Infrastructure Servers.
            Computers with server operating systems will be added to this group if found.

        .PARAMETER PawGroup
            Specifies the distinguished name or group identifier for the group that contains all PAW (Privileged Access Workstation) machines.
            Non-server machines will be added to this group if found.

        .EXAMPLE
            Set-PrivilegedComputerHousekeeping -SearchRootDN "OU=Admin,DC=EguibarIT,DC=local" -InfraGroup 'SL_InfrastructureServers' -PawGroup 'SL_PAWs'

            Description:
            This example runs the housekeeping process for computers within the "OU=Admin,DC=EguibarIT,DC=local" organizational unit.
            It adds server computers to the 'SL_InfrastructureServers' group and PAWs to the 'SL_PAWs' group based on their operating system.

        .EXAMPLE
            Set-PrivilegedComputerHousekeeping -SearchRootDN "OU=Servers,DC=EguibarIT,DC=local" -InfraGroup 'Infra_Servers_Group' -PawGroup 'PAW_Group' -WhatIf

            Description:
            This example shows what the function would do (without actually performing the changes) if it were to run on the "OU=Servers" organizational
            unit, adding servers to the 'Infra_Servers_Group' and PAWs to the 'PAW_Group'. The `-WhatIf` parameter simulates the execution.

        .INPUTS
            None.
            The function does not accept input objects from the pipeline.

        .OUTPUTS
            None.
            This function does not return any objects. It uses verbose messages for output and updates Active Directory objects.


        .NOTES
            Used Functions:
                Name                                   ║ Module
                =======================================╬==========================
                Get-ADComputer                         ║ ActiveDirectory
                Remove-ADGroupMember                   ║ ActiveDirectory
                Add-ADGroupMember                      ║ ActiveDirectory
                Import-Module                          ║ Microsoft.PowerShell.Core
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Progress                         ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS
                Test-IsValidDN                         ║ EguibarIT.HousekeepingPS
                Get-AdObjectType                       ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    17/May/2024
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
            https://www.delegationmodel.com/

    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'low')]
    [OutputType([void])]

    param(

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $SearchRootDN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Identity of the group of all Infrastructure Servers.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('InfrastructureServers', 'AllServers', 'ServersGroupID')]
        $InfraGroup,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Identity of the group of all PAWs.',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('Paws', 'AllPaws', 'PawGroupID')]
        $PawGroup
    )

    Begin {
        # Set strict mode
        Set-StrictMode -Version Latest

        # Display function header if variables exist
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
        # Module Import

        Import-MyModule ActiveDirectory

        ##############################
        # Variables Definition

        # Parameters variable for splatting cmdlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        [int]$i = 0

        [hashtable]$stats = @{
            NewServer = 0
            NewPAW    = 0
        }

        # Lists for computers
        [System.Collections.Generic.List[Object]]$AllPrivComputers = [System.Collections.Generic.List[Object]]::new()

        # Get Infrastructure Servers group
        $InfraGroupObj = Get-AdObjectType -Identity $PsBoundParameters['InfraGroup']
        if (-not $InfraGroupObj) {
            Throw "Infrastructure Servers group ($InfraGroup) not found."
        } #end If

        $PawGroupObj = Get-AdObjectType -Identity $PsBoundParameters['PawGroup']
        if (-not $PawGroupObj) {
            Throw "PAW group ($PawGroup) not found."
        } #end If

    } #end Begin

    Process {
        try {
            Write-Verbose -Message 'Getting the list of ALL T0 servers and PAW computers.'
            [string[]]$Props = @(
                'OperatingSystem',
                'SamAccountName',
                'DistinguishedName'
            )

            $Splat = @{
                Filter     = '*'
                Properties = $Props
                SearchBase = $PsBoundParameters['SearchRootDN']
            }
            $AllPrivComputers = Get-ADComputer @Splat | Select-Object -Property $Props

            [int]$TotalObjectsFound = $AllPrivComputers.Count
            if ($TotalObjectsFound -eq 0) {
                Write-Verbose -Message ('No computers found in the search root: {0}.' -f $SearchRootDN)
                return
            } #end If

            # Iterate all found items
            Foreach ($item in $AllPrivComputers) {
                $i++

                $error.Clear()

                # Display the progress bar
                $parameters = @{
                    Activity        = 'Checking computers within Admin Area'
                    Status          = "Working on item No. $i from $TotalObjectsFound"
                    PercentComplete = ($i / $TotalObjectsFound * 100)
                }
                Write-Progress @parameters

                # exclude all computers within Housekeeping
                if ($item.DistinguishedName -notlike '*Housekeeping*') {
                    try {
                        $targetGroup = if ($item.OperatingSystem -like '*Server*') {
                            $InfraGroupObj
                            $stats.NewServer++
                        } else {
                            $PawGroupObj
                            $stats.NewPAW++
                        } #end If-Else

                        if ($PSCmdlet.ShouldProcess($item.SamAccountName, "Add to $($targetGroup.Name)")) {
                            Add-ADGroupMember -Identity $targetGroup -Members $item -ErrorAction Stop

                            Write-Verbose -Message ('Added {0} to {1}' -f
                                $item.SamAccountName, $targetGroup.Name)
                        } #end If
                    } catch {
                        Write-Warning -Message ('Failed to process computer {0}: {1}' -f
                            $item.SamAccountName, $_.Exception.Message)
                    } #end Try-Catch
                } #end If
            } #end Foreach
        } catch {
            Write-Error -Message ('Error processing computers: {0}' -f $_.Exception.Message)
        } #end Try-Catch
    } #end Process

    End {
        if ($null -ne $Constants -and $null -ne $Constants.NL) {
            Write-Verbose -Message $Constants.NL
        }

        Write-Verbose -Message 'Any semi-privileged and/or Privileged computer will be patched and managed by Tier0 services'

        if ($null -ne $Constants -and $null -ne $Constants.NL) {
            Write-Verbose -Message $Constants.NL
        }

        Write-Verbose -Message ('Servers found...: {0}' -f $stats.NewServer)
        Write-Verbose -Message ('PAWs found......: {0}' -f $stats.NewPAW)

        if ($null -ne $Constants -and $null -ne $Constants.NL) {
            Write-Verbose -Message $Constants.NL
        }

        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'setting Infrastructure Servers / PAWs housekeeping.'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end End
} #end Function Set-PrivilegedComputerHousekeeping
