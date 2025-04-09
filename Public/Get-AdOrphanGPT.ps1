Function Get-AdOrphanGPT {

    <#
        .SYNOPSIS
            Finds and optionally removes orphaned Group Policy Templates (GPTs) in SYSVOL.

        .DESCRIPTION
            Searches for GPT folders within the SYSVOL directory and compares them against
            GPOs listed in Active Directory to identify and optionally remove orphaned GPTs.
            Supports credential delegation and remote domain controller specification.

        .PARAMETER RemoveOrphanGPT
            Switch to specify whether to remove orphaned GPT directories if found.

        .PARAMETER DomainController
            Specifies the domain controller to query. If not specified, uses the default DC.

        .PARAMETER Credential
            Specifies credentials to use for the operation. If not specified, uses current user context.

        .OUTPUTS
            [PSCustomObject] Array of objects containing:
                Name: Name of the orphaned GPT
                Path: Full path to the GPT
                Removed: Boolean indicating if it was removed (if RemoveOrphanGPT was specified)

        .EXAMPLE
            Get-AdOrphanGPT -Verbose
            Lists all orphaned GPTs with verbose output.

        .EXAMPLE
            Get-AdOrphanGPT -RemoveOrphanGPT -Credential (Get-Credential)
            Finds and removes orphaned GPTs using specified credentials.

        .NOTES
            Used Functions:
                Name                                   ║ Module
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ADDomain                           ║ ActiveDirectory
                Get-ADObject                           ║ ActiveDirectory
                Get-ChildItem                          ║ Microsoft.PowerShell.Management
                Remove-Item                            ║ Microsoft.PowerShell.Management
                Write-Progress                         ║ Microsoft.PowerShell.Utility
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS
                Import-MyModule                        ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.5
            DateModified:    08/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'Default'
    )]
    [OutputType([PSCustomObject[]])]

    Param (

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'If present will remove any Orphan GPT.',
            Position = 0)]
        [switch]
        $RemoveOrphanGPT,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain Controller to query.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainController

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

        Import-MyModule ActiveDirectory -Force -Verbose:$false


        ##############################
        # Variables Definition

        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        [hashtable]$ADParams = @{
            ErrorAction = 'Stop'
        }

        if ($PSBoundParameters.ContainsKey('DomainController')) {
            $ADParams['Server'] = $DomainController
        } #end If

        # Initialize collections
        $gpos = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $gpts = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Construct SYSVOL path and GPC DN
        $unc = '\\{0}\SYSVOL\{0}\Policies' -f $Variables.DnsFqdn
        $GPOPoliciesDN = 'CN=Policies,CN=System,{0}' -f $Variables.defaultNamingContext

    } #end Begin

    process {

        try {
            Write-Progress -Activity 'Processing GPOs' -Status 'Querying AD...' -PercentComplete 0

            # Query AD for GPOs using DirectorySearcher for better performance
            $gpoc = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$GPOPoliciesDN")
            $searcher = [System.DirectoryServices.DirectorySearcher]::new($gpoc)
            $searcher.PageSize = 1000
            $searcher.SearchScope = 'OneLevel'

            $results = $searcher.FindAll()
            $total = $results.Count
            $current = 0

            foreach ($result in $results) {

                $current++

                $Splat = @{
                    Activity        = 'Processing GPOs'
                    Status          = 'Reading GPO entries...'
                    PercentComplete = (($current / $total) * 50)
                }
                Write-Progress @Splat

                $gpoName = $result.Properties['name'][0]
                [void]$gpos.Add($gpoName.Replace('CN=', ''))

            } #end foreach

            $searcher.Dispose()
            $gpoc.Dispose()

            # Process SYSVOL directories
            Write-Progress -Activity 'Processing GPOs' -Status 'Scanning SYSVOL...' -PercentComplete 50

            $dirs = Get-ChildItem -Path $unc -Directory
            $total = $dirs.Count
            $current = 0

            foreach ($dir in $dirs) {

                $current++

                $splat = @{
                    Activity        = 'Processing GPOs'
                    Status          = 'Checking GPT folders...'
                    PercentComplete = (50 + ($current / $total) * 50)
                }
                Write-Progress @Splat

                if (-not $dir.Name.Contains('PolicyDefinitions')) {

                    $gpts.Add([PSCustomObject]@{
                            Name    = $dir.Name
                            Path    = $dir.FullName
                            Removed = $false
                        })
                } #end If

            } #end foreach

            # Identify and process orphaned GPTs
            $OrphanedGPTs = $gpts.Where({ $_.Name -notin $gpos })
            Write-Verbose -Message ('Found {0} Orphaned GPTs' -f $OrphanedGPTs.Count)

            if ($RemoveOrphanGPT -and $OrphanedGPTs.Count -gt 0) {

                foreach ($gpt in $OrphanedGPTs) {

                    $warningMsg = ('About to remove orphaned GPT: {0}' -f $gpt.Name)
                    if ($PSCmdlet.ShouldProcess($gpt.Path, $warningMsg)) {

                        try {

                            Remove-Item -Path $gpt.Path -Recurse -Force -ErrorAction Stop
                            $gpt.Removed = $true
                            Write-Verbose -Message ('Successfully removed orphan GPT: {0}' -f $gpt.Name)

                        } catch {

                            Write-Error -Message ('Failed to remove GPT {0}: {1}' -f $gpt.Name, $_.Exception.Message)

                        } #end Try/Catch
                    } #end If ShouldProcess
                } #end foreach
            } #end If RemoveOrphanGPT

        } catch {

            Write-Error -Message ('An error occurred while processing orphaned GPTs: {0}' -f $_.Exception.Message)
            throw

        } finally {

            Write-Progress -Activity 'Processing GPOs' -Completed

        } #end Try-Catch-Finally

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing orphaned GPTs.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $OrphanedGPTs
    } #end End
} #end Function Get-AdOrphanGPT
