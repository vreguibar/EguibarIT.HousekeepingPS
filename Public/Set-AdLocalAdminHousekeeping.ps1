Function Set-AdLocalAdminHousekeeping {
    <#
        .SYNOPSIS
            Manage local administrative groups for servers in a domain.

        .DESCRIPTION
            This function performs housekeeping for local administrative groups on servers within a domain.
            It performs the following tasks:
            1. Retrieves all servers in the domain (excluding Domain Controllers)
            2. For each server, ensures a corresponding Admin_<HostName> group exists
            3. Creates missing Admin_<HostName> groups at specified LDAP path
            4. Removes obsolete Admin_<HostName> groups for non-existent servers
            5. Validates group naming conventions and location

            The function follows Active Directory tiering model and security best practices.
            Optimized for large environments with 100,000+ objects.

        .PARAMETER Domain
            Specifies the domain to perform the operations on.
            If not specified, uses the current domain from $Env:USERDNSDOMAIN.

        .PARAMETER LDAPPath
            Specifies the LDAP path where the Admin_<HostName> groups should be created.
            Example: "OU=SpecialGroups,DC=example,DC=com"
            Must be a valid Distinguished Name (DN).

        .EXAMPLE
            Set-AdLocalAdminHousekeeping -Domain "example.com" -LDAPPath "OU=SpecialGroups,DC=example,DC=com"
            Creates or manages Admin_* groups for all servers in example.com domain.

        .EXAMPLE
            Set-AdLocalAdminHousekeeping -LDAPPath "OU=AdminGroups,DC=contoso,DC=com" -Verbose
            Creates or manages Admin_* groups in current domain with verbose output.

        .INPUTS
            System.String
            You can pipe domain names and LDAP paths to this function.

        .OUTPUTS
            None. This function does not generate any output.

        .NOTES
            Used Functions:
                Name                                   ║ Module/Namespace
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ADComputer                         ║ ActiveDirectory
                Get-ADGroup                            ║ ActiveDirectory
                New-ADGroup                            ║ ActiveDirectory
                Remove-ADGroup                         ║ ActiveDirectory
                Get-ADDomainController                 ║ ActiveDirectory
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  ║ EguibarIT.HousekeepingPS
                Test-IsValidDN                         ║ EguibarIT.HousekeepingPS
                Import-MyModule                        ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.1
            DateModified:    10/Apr/2025
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT

        .COMPONENT
            Active Directory
            Windows Server Administration

        .ROLE
            Domain Administrator
            Enterprise Administrator

        .FUNCTIONALITY
            Active Directory
            Group Management
            Server Administration
            Security
            Housekeeping
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([System.Void])]

    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Domain to perform operations on. Defaults to current domain.',
            Position = 0)]
        [PSDefaultValue(
            Help = 'Use current domain from $Env:USERDNSDOMAIN if parameter value is not provided.',
            Value = { $Env:USERDNSDOMAIN }
        )]
        [string]
        $Domain = $Env:USERDNSDOMAIN,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'LDAP path where Admin groups will be created/managed.',
            Position = 1)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'DistinguishedName provided is not valid! Please Check.'
        )]
        [Alias('DN', 'DistinguishedName', 'Path')]
        [String]
        $LDAPpath
    )

    begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports

        # Verify the Active Directory module is loaded
        Import-MyModule ActiveDirectory -Verbose:$false

        ##############################
        # Variables Definition

        # explicit type declaration of HashTable
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
        [string]$DomainControllerName = $null

        try {

            # If Domain parameter is null or empty, use current domain
            if ([string]::IsNullOrWhiteSpace($Domain)) {
                if ([string]::IsNullOrWhiteSpace($Env:USERDNSDOMAIN)) {
                    throw 'Unable to determine domain.
                        Please specify the Domain parameter or ensure the computer is domain-joined.'
                } #end if
                $Domain = $Env:USERDNSDOMAIN
            } #end if

            Write-Verbose -Message ('Attempting to discover domain controller for domain: {0}' -f $Domain)

            # Try to discover a domain controller
            try {
                $domainController = Get-ADDomainController -Discover -DomainName $Domain -ErrorAction Stop
                $DomainControllerName = $domainController.HostName.ToString()
            } catch {
                Write-Warning -Message ('Domain controller discovery failed for {0}: {1}' -f $Domain, $_.Exception.Message)

                # Fallback: try to get any available domain controller for the current domain
                try {
                    Write-Verbose -Message 'Attempting fallback: Getting any available domain controller...'
                    $domainController = Get-ADDomainController -ErrorAction Stop
                    $DomainControllerName = $domainController.HostName.ToString()
                    Write-Verbose -Message ('Using fallback domain controller: {0}' -f $DomainControllerName)
                } catch {
                    throw (
                        'Unable to locate any domain controller.
                        Please verify:
                            1) Active Directory Web Services is running on domain controllers,
                            2) Network connectivity is available,
                            3) DNS resolution is working properly. Error: {0}' -f
                        $_.Exception.Message
                    )
                } #end try-catch
            } #end try-catch

            Write-Verbose -Message ('Using domain controller {0} for domain operations.' -f $DomainControllerName)

            # Get all computer objects categorized as servers, excluding Domain Controllers
            $Splat = @{
                LDAPFilter = '(&(objectClass=computer)(operatingSystem=*server*)(!(primaryGroupID=516)))'
                Server     = $DomainControllerName
                Properties = 'Name'
            }
            $servers = Get-ADComputer @Splat
            Write-Verbose -Message ('Retrieved {0} servers from the domain.' -f @($servers).Count)

        } catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {

            Write-Error -Message (
                'Unable to connect to domain controller: {0}.
                Please verify that Active Directory Web Services is running and the server is accessible.' -f
                $_.Exception.Message
            )
            return

        } catch [System.ComponentModel.Win32Exception] {

            Write-Error -Message (
                'Network or DNS error: {0}.
                Please verify network connectivity and DNS resolution.' -f
                $_.Exception.Message
            )
            return

        } catch {

            Write-Error -Message ('Error during initialization: {0}' -f $_.Exception.Message)
            return

        } #end Try-Catch

    } #end Begin

    process {

        $progressParams = @{
            Activity = 'Processing Server Admin Groups'
            Status   = 'Starting server group management'
        }
        Write-Progress @progressParams

        $serverCount = @($servers).Count
        $currentServer = 0

        # Ensure each server has a corresponding Admin_<HostName> group
        foreach ($server in $servers) {

            $currentServer++
            $progressParams.Status = ('Processing server {0} of {1}' -f $currentServer, $serverCount)
            $progressParams.PercentComplete = ($currentServer / $serverCount * 100)
            Write-Progress @progressParams

            try {
                # Find the corresponding Administrative group name
                $groupName = 'Admin_{0}' -f $server.Name

                # Get the group. If NotFound exception variable will be Null
                $group = Get-ADGroup -Filter { Name -eq $groupName } -Server $DomainControllerName -ErrorAction SilentlyContinue

                if (-not $group) {

                    if ($PSCmdlet.ShouldProcess($groupName, 'Create administrative group')) {

                        $Splat = @{
                            Name          = $groupName
                            GroupCategory = 'Security'
                            GroupScope    = 'Global'
                            DisplayName   = '{0} Local Administrators members' -f $server.Name
                            Path          = $PsBoundParameters['LDAPPath']
                            Description   = 'Local Admin group for {0}' -f $server.Name
                            Server        = $DomainControllerName
                            ErrorAction   = 'Stop'
                        }
                        New-ADGroup @Splat
                        Write-Verbose -Message ('Created group {0} at {1}.' -f $groupName, $PsBoundParameters['LDAPPath'])

                    } #end If

                } #end If

            } catch [Microsoft.ActiveDirectory.Management.ADException] {

                Write-Warning -Message ('Failed to process server {0}: {1}' -f $server.Name, $_.Exception.Message)
                continue

            } #end Try-Catch

        } #end ForEach

        Write-Progress @progressParams -Completed

        # Cleanup obsolete groups
        Write-Verbose -Message 'Starting cleanup of obsolete admin groups'

        try {
            # Check all groups on given LDAPPAth for obsolete entries
            $Splat = @{
                Filter     = '*'
                Server     = $DomainControllerName
                SearchBase = $PsBoundParameters['LDAPPath']
                Properties = 'Members'
            }
            $adminGroups = Get-ADGroup @Splat

            #iterate all found groups
            foreach ($group in $adminGroups) {

                # Exclude groups that do not follow the naming convention
                if ($group.Name -match '^Admin_[A-Za-z0-9_-]+$') {

                    # Extract server name from group name
                    $hostName = $group.Name -replace '^Admin_', ''

                    # Find the corresponding server object
                    $server = $servers | Where-Object { $_.Name -eq $hostName }

                    if (-not $server) {

                        if ($PSCmdlet.ShouldProcess($group.Name, 'Delete obsolete group')) {

                            Remove-ADGroup -Identity $group -Confirm:$false -Server $DomainControllerName
                            Write-Verbose -Message (
                                'Deleted obsolete group {0} because the corresponding server no longer exists.' -f
                                $group.Name
                            )

                        } #end If

                    } #end If

                } else {

                    if ($PSCmdlet.ShouldProcess($group.Name, 'Delete non-compliant group')) {

                        # Remove this group because it does not follow naming convention
                        Remove-ADGroup -Identity $group -Confirm:$false -Server $DomainControllerName
                        Write-Verbose -Message (
                            'Deleted non-compliant group {0} because it does not follow the naming conventions.' -f
                            $group.Name
                        )

                    } #end If

                } #end If-Else

            } #end ForEach

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {

            Write-Warning -Message ('Group not found during cleanup: {0}' -f $_.Exception.Message)

        } catch {

            Write-Error -Message ('Error during group cleanup: {0}' -f $_.Exception.Message)

        } #end Try-Catch

    } #end Process

    end {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'creating corrresponding Admin_<HostName> group.'
            )
            Write-Verbose -Message $txt
        } #end If

    } #end End
} #end function Set-AdLocalAdminHousekeeping

