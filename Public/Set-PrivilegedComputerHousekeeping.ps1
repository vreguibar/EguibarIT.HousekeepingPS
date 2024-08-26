Function Set-PrivilegedComputerHousekeeping {
    <#
        .SYNOPSIS
            Check and manage privileged computers (PAWs and Infrastructure Servers).

        .DESCRIPTION
            This script checks for privileged and semi-privileged computers in specified OU
            within Active Directory, updating group memberships as necessary.

        .PARAMETER SearchRootDN
            Specifies the distinguished name of the search root in Active Directory.

        .PARAMETER InfraGroup
            Identity of the group of all Infrastructure Servers

        .PARAMETER PawGroup
            Identity of the group of all PAWs

        .EXAMPLE
            Set-PrivilegedComputerHousekeeping -SearchRootDN "OU=Admin,DC=EguibarIT,DC=local" -InfraGroup 'SL_InfrastructureServers' -PawGroup 'SL_PAWs'

        .OUTPUTS
            Outputs verbose information about processing and errors if any occur.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADComputer                         | ActiveDirectory
                Remove-ADGroupMember                   | ActiveDirectory
                Add-ADGroupMember                      | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Progress                         | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-AdObjectType                       | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:        1.0
            Author:         Your Name
            Creation Date:  2024-04-25
            Purpose/Change: Initial script development.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'low')]

    param(

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $SearchRootDN,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Identity of the group of all Infrastructure Servers.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('InfrastructureServers', 'AllServers', 'ServersGroupID')]
        $InfraGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Identity of the group of all PAWs.',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('Paws', 'AllPaws', 'PawGroupID')]
        $PawGroup

    )

    Begin {
       $txt = ($constants.Header -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        [int]$i = 0
        [int]$NewServer = 0
        [int]$NewPAW = 0

        # Lists for computers
        $AllPrivComputers = [System.Collections.Generic.List[Object]]::new()

        # Get Infrastructure Servers group
        $InfraGroup = Get-AdObjectType -Identity $PsBoundParameters['InfraGroup']

        $PawGroup = Get-AdObjectType -Identity $PsBoundParameters['PawGroup']

    } #end Begin

    Process {

        Write-Verbose -Message 'Getting the list of ALL T0 servers and PAW computers.'
        $Props = @(
            'OperatingSystem',
            'SamAccountName',
            'DistinguishedName'
        )
        $AllPrivComputers = Get-ADComputer -Filter * -Properties $Props -SearchBase $PsBoundParameters['SearchRootDN'] | Select-Object $Props

        # Iterate all found items
        Foreach ($item in $AllPrivComputers) {
            $i ++

            $error.Clear()

            # Display the progress bar
            $parameters = @{
                Activity        = 'Checking computers within Admin Area'
                Status          = "Working on item No. $i from $TotalObjectsFound"
                PercentComplete = ($i / $TotalObjectsFound * 100)
            }
            Write-Progress @parameters

            If (-not($item.DistinguishedName.Contains('Housekeeping'))) {

                If ($item.OperatingSystem -like '*Server*') {

                    Add-ADGroupMember -Identity $InfraGroup -Members $Item.SamAccountName
                    Write-Verbose ('Adding found Server {0} to SL_InfrastructureServers group' -f $Item.SamAccountName)
                    $NewServer ++

                } else {

                    Add-ADGroupMember -Identity $PawGroup -Members $Item.SamAccountName
                    Write-Verbose ('Adding found PAW {0} to SL_PAWs group' -f $Item.SamAccountName)
                    $NewPAW ++

                } #end If-Else
            } #end If
        } #end Foreach

    } #end Process

    End {
        $Constants.NL
        Write-Verbose 'Any semi-privileged and/or Privileged computer will be patched and managed by Tier0 services'
        $Constants.NL
        Write-Verbose ('Servers found..: {0}' -f $NewServer)
        Write-Verbose ('PAWs found.   .: {0}' -f $NewPAW)
        $Constants.NL
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished setting Infrastructure Servers / PAWs housekeeping."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
