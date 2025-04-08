Function Get-AdOrphanGPO {
    <#
        .SYNOPSIS
            Identify and optionally remove orphaned Group Policy Objects (GPOs).

        .DESCRIPTION
            This function identifies and manages orphaned GPOs - those that exist in Active Directory
            but lack corresponding policy folders in SYSVOL. It can optionally remove these orphaned
            objects to maintain AD health.

        .PARAMETER RemoveOrphanGPOs
            If specified, orphaned GPOs will be removed. Use with caution.

        .EXAMPLE
            Get-AdOrphanGPO
            Lists all orphaned GPOs without removing them.

        .EXAMPLE
            Get-AdOrphanGPO -RemoveOrphanGPOs -Verbose
            Removes orphaned GPOs with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success       : Boolean indicating if operations completed successfully
                OrphanedGPOs  : Array of orphaned GPO objects found
                RemovedGPOs   : Array of GPOs successfully removed (if RemoveOrphanGPOs specified)
                Errors        : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                      ║ Module/Namespace
                ══════════════════════════════════════════╬══════════════════════════════
                Get-ADObject                              ║ ActiveDirectory
                Get-ChildItem                             ║ Microsoft.PowerShell.Management
                Test-Path                                 ║ Microsoft.PowerShell.Management
                Join-Path                                 ║ Microsoft.PowerShell.Management
                Get-GPO                                   ║ GroupPolicy
                Write-Verbose                             ║ Microsoft.PowerShell.Utility
                Write-Warning                             ║ Microsoft.PowerShell.Utility
                Write-Error                               ║ Microsoft.PowerShell.Utility
                Write-Progress                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                       ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.4
            DateModified:    8/Apr/2025
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    [OutputType([PSCustomObject])]

    Param(

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'If present will remove any Orphan GPO.',
            Position = 0)]
        [PSDefaultValue(Help = 'Default Value is "FALSE"',
            Value = $false
        )]
        [switch]
        $RemoveOrphanGPOs

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

        Import-MyModule -ModuleName 'ActiveDirectory' -Verbose:$false
        Import-MyModule -ModuleName 'GroupPolicy' -Verbose:$false


        ##############################
        # Variables Definition

        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
        [int]$current = 0

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            OrphanedGPOs = @()
            RemovedGPOs  = @()
            Errors       = @()
        }

        $sysvolPolicies = @{}

        # Construct SYSVOL path and GPC DN
        $sysvolPath = '\\{0}\SYSVOL\{0}\Policies' -f $Variables.DnsFqdn
        $policiesDN = 'CN=Policies,CN=System,{0}' -f $Variables.defaultNamingContext

        Write-Debug -Message ('SYSVOL path: {0}' -f $sysvolPath)
        Write-Debug -Message ('Policies DN: {0}' -f $policiesDN)

    } #end Begin

    Process {

        try {
            Write-Progress -Activity 'Processing GPOs' -Status 'Getting AD GPO objects...'

            # Get GPOs from Active Directory
            $Splat = @{
                LDAPFilter = '(objectClass=groupPolicyContainer)'
                SearchBase = $policiesDN
                Properties = 'DisplayName', 'whenChanged'
            }
            $adGpos = Get-ADObject @Splat

            Write-Progress -Activity 'Processing GPOs' -Status 'Getting SYSVOL policies...'

            # Get SYSVOL policies and create lookup hash for better performance

            Get-ChildItem -Path $sysvolPath -Directory |
                Where-Object { $_.Name -ne 'PolicyDefinitions' } |
                    ForEach-Object { $sysvolPolicies[$_.Name] = $_ }

            Write-Debug -Message ('Found {0} SYSVOL policies' -f $sysvolPolicies.Count)

            # Find orphaned GPOs using the hash lookup (much faster than Test-Path)
            $orphanedGpos = $adGpos | Where-Object {
                $gpoId = $_.Name -replace 'CN=', ''
                -not $sysvolPolicies.ContainsKey($gpoId)
            }

            $result.OrphanedGPOs = @($orphanedGpos)
            Write-Verbose -Message ('Found {0} orphaned GPOs' -f $orphanedGpos.Count)

            # Remove orphaned GPOs if requested
            if ($RemoveOrphanGPOs -and $orphanedGpos) {

                $total = $orphanedGpos.Count
                $current = 0

                foreach ($gpo in $orphanedGpos) {

                    $current++
                    $Splat = @{
                        Activity        = 'Removing Orphaned GPOs'
                        Status          = ('Processing {0}' -f $gpo.DisplayName)
                        PercentComplete = (($current / $total) * 100)
                    }
                    Write-Progress

                    $message = ('Remove orphaned GPO: {0} (Last changed: {1})' -f
                        $gpo.DisplayName, $gpo.whenChanged)

                    if ($PSCmdlet.ShouldProcess($message, 'Remove GPO')) {

                        try {

                            $gpoGuid = [Guid]($gpo.Name -replace 'CN=', '')
                            $gpoObject = Get-GPO -Guid $gpoGuid -ErrorAction Stop
                            $gpoObject.Delete()

                            $result.RemovedGPOs += $gpo.DisplayName
                            Write-Debug -Message ('Removed GPO: {0}' -f $gpo.DisplayName)

                        } catch {

                            $errorMsg = ('Failed to remove GPO {0}: {1}' -f
                                $gpo.DisplayName, $_.Exception.Message)
                            Write-Warning -Message $errorMsg
                            $result.Errors += $errorMsg

                        } #end Try/Catch

                    } #end If

                } #end ForEach

            } #end If

            $result.Success = ($result.Errors.Count -eq 0)

        } catch {

            $errorMsg = ('Operation failed: {0}' -f $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg

        } finally {

            Write-Progress -Activity 'Processing GPOs' -Completed

        } #end try/catch/finally

    } #end Process

    End {
        Write-Verbose -Message ('Found {0} orphaned GPOs, Removed {1}, Errors: {2}' -f
            $result.OrphanedGPOs.Count,
            $result.RemovedGPOs.Count,
            $result.Errors.Count)

        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing orphaned GPOs.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end Function Get-AdOrphanGPO
