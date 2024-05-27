Function Get-AdOrphanGPT {
    <#
        .SYNOPSIS
            Finds orphaned Group Policy Templates (GPTs) that do not have a corresponding Group Policy Object (GPO).

        .DESCRIPTION
            This script searches for GPT folders within the SYSVOL directory and compares them against
            GPOs listed in Active Directory to identify any orphaned GPTs.

        .EXAMPLE
            Get-AdOrphanGPT -RemoveOrphanGPT $true

        .PARAMETER RemoveOrphanGPT
         Indicates whether to remove the orphaned GPT directories.

        .OUTPUTS
            Array of orphaned GPTs.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                New-Object                             | Microsoft.PowerShell.Utility
                Get-ChildItem                          | Microsoft.PowerShell.Management
                Remove-Item                            | Microsoft.PowerShell.Management
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Output                           | Microsoft.PowerShell.Utility
                Write-Error                            | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.4
            DateModified:    12/Mar/2024
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]

    param (
        [Parameter(Mandatory = $false)]
        [bool]$RemoveOrphanGPT = $false
    )

    Begin {
        Write-Verbose -Message '|=> ************************************************************************ <=|'
        Write-Verbose -Message (Get-Date).ToShortDateString()
        Write-Verbose -Message ('  Starting: {0}' -f $MyInvocation.Mycommand)
        Write-Verbose -Message ('Parameters used by the function... {0}' -f (Get-FunctionDisplay $PsBoundParameters -Verbose:$False))

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        # Construct SYSVOL path and GPC DN
        $unc = '\\{0}\SYSVOL\{0}\Policies' -f $Variables.DnsFqdn
        $GPOPoliciesDN = 'CN=Policies,CN=System,{0}' -f $Variables.defaultNamingContext

        $gpos = New-Object System.Collections.ArrayList
        $gpts = New-Object System.Collections.ArrayList
    } #end Begin

    process {
        try {
            $gpoc = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$GPOPoliciesDN")
            $store = $gpoc.Children

            foreach ($gpo in $store) {
                $gpos.Add($gpo.Name.Replace('CN=', ''))
            }

            $dirs = Get-ChildItem -Path $unc -Directory

            foreach ($dir in $dirs) {
                if (-not $dir.Name.Contains('PolicyDefinitions')) {
                    $gpts.Add($dir.Name)
                }
            }

            $OrphanedGPTs = $gpts.ToArray() | Where-Object { $_ -notin $gpos.ToArray() }

            Write-Verbose ("Found $($OrphanedGPTs.Count) Orphaned GPTs")
            Write-Output $OrphanedGPTs

            if ($RemoveOrphanGPT) {
                foreach ($gptDir in $OrphanedGPTs) {
                    Write-Verbose ("Deleting $gptDir Orphan GPT and all content.")
                    Remove-Item -Path "$unc\$gptDir" -Recurse -Force
                }
            }
        } catch {
            Write-Error "An error occurred: $_"
            throw
        }
    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished getting and removing Orphan GPTs."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
