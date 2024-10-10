Function Set-AdLocalAdminHousekeeping {
    <#
        .SYNOPSIS
            Manage local administrative groups for servers in a domain.

        .DESCRIPTION
            This function performs housekeeping for local administrative groups on servers within a domain. It will:
            A) Retrieve all servers in the domain.
            B) Ensure each server has a corresponding local admin group named 'Admin_<HostName>'.
               If such a group does not exist, it will be created at the specified LDAP path.
            C) Check if each 'Admin_<HostName>' group corresponds to an existing server.
               If the server does not exist in AD, the group will be deleted.

        .PARAMETER Domain
            Specifies the domain to perform the operations on.

        .PARAMETER LDAPPath
            Specifies the LDAP path where the 'Admin_<HostName>' groups should be created.
            Example: "OU=SpecialGroups,DC=example,DC=com"

        .EXAMPLE
            Set-AdLocalAdminHousekeeping -Domain "example.com" -LDAPPath "OU=SpecialGroups,DC=example,DC=com"

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADComputer                         | ActiveDirectory
                Get-ADGroup                            | ActiveDirectory
                New-ADGroup                            | ActiveDirectory
                Remove-ADGroup                         | ActiveDirectory
                Get-ADDomainController                 | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Error                            | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    10/May/2024
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'low')]

    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Specifies the domain to perform the operations on.',
            Position = 0)]
        [PSDefaultValue(Help = 'Use current domain from $Env:USERDNSDOMAIN if parameter value is not provided.')]
        [string]
        $Domain = $Env:USERDNSDOMAIN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Admin Groups OU Distinguished Name.',
            Position = 1)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName')]
        [String]
        $LDAPpath
    )

    begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        Import-MyModule ActiveDirectory -Verbose:$false

        ##############################
        # Variables Definition

        # explicit type declaration of HashTable
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)


        # Find a domain controller in the specified domain
        $domainController = Get-ADDomainController -Discover -DomainName $PsBoundParameters['Domain']

        if (-not $domainController) {
            Write-Error 'No domain controllers found for domain {0}' -f $PsBoundParameters['Domain']
            return
        } #end If
        Write-Verbose -Message ('Using domain controller {0} for domain operations.' -f $($domainController.HostName))


        # Get all computer objects categorized as servers, excluding 'Domain Controllers'
        $Splat = @{
            Filter   = '( (OperatingSystem -Like "*Server*") -and (PrimaryGroupID -ne 516) )'
            Server   = $domainController.HostName
            Property = 'Name'
        }
        $servers = Get-ADComputer @Splat
        Write-Verbose -Message ('Retrieved {0} servers from the domain.' -f $servers.Count)

    } #end Begin

    process {
        try {

            # Ensure each server has a corresponding Admin_<HostName> group
            foreach ($server in $servers) {

                # Find the corresponding Administrative group name
                $groupName = 'Admin_{0}' -f $server.Name

                # Get the group. If NotFound exception variable will be Null
                $group = Get-ADGroup -Filter { Name -eq $groupName } -Server $($domainController.HostName) -ErrorAction SilentlyContinue

                if (-not $group) {
                    if ($PSCmdlet.ShouldProcess($groupName, 'Create group')) {
                        $Splat = @{
                            Name          = $groupName
                            GroupCategory = 'Security'
                            GroupScope    = 'Global'
                            DisplayName   = '{0} Local Administrators members' -f $server.Name
                            Path          = $PsBoundParameters['LDAPPath']
                            Description   = 'Local Admin group for {0}' -f $server.Name
                            Server        = $($domainController.HostName)
                        }
                        New-ADGroup @Splat
                        Write-Verbose -Message ('Created group {0} at {1}.' -f $groupName, $PsBoundParameters['LDAPPath'])
                    } #end If
                } #end If
            } #end ForEach

            # Check all groups on given LDAPPAth for obsolete entries
            $adminGroups = Get-ADGroup -Filter * -Server $($domainController.HostName) -SearchBase $PsBoundParameters['LDAPPath'] -Properties Members

            #iterate all found groups
            foreach ($group in $adminGroups) {

                # Exclude groups that do not follow the naming convention
                if ($group.Name -match '^Admin_[A-Za-z0-9_-]+$') {

                    # Extract server name from group name
                    $hostName = $group.Name -replace '^Admin_', ''

                    # Find the corresponding server object
                    $server = $servers | Where-Object { $_.Name -eq $hostName }

                    if (-not $server) {

                        if ($PSCmdlet.ShouldProcess($group.Name, 'Delete group')) {
                            Remove-ADGroup -Identity $group -Confirm:$false -Server $($domainController.HostName)
                            Write-Verbose -Message ('Deleted group {0} because the corresponding server no longer exists.' -f $group.Name)
                        } #end If

                    } #end If
                } else {
                    # Remove this group because it does not follow naming convention, or it does not belongs to this OU.
                    Remove-ADGroup -Identity $group -Confirm:$false -Server $($domainController.HostName)
                    Write-Verbose -Message ('Deleted group {0} because does not follow the naming conventions.' -f $group.Name)
                }#end If
            } #end ForEach
        } catch {
            Write-Error -Message ('An error occurred: {0}' -f $_)
        } #end Try-Catch
    } #end Process

    end {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'setting group for Local Administrators.'
        )
        Write-Verbose -Message $txt
    } #end End
} #end function Set-AdLocalAdminHousekeeping

