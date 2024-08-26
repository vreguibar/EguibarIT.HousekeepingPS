Function Get-AdOrphanGPO {
    <#
        .SYNOPSIS
            Identify and optionally remove orphaned Group Policy Objects (GPOs).

        .DESCRIPTION
            This script identifies orphaned GPOs that do not have corresponding GPTs in the SYSVOL folder and optionally removes them.

        .PARAMETER RemoveOrphanGPOs
            Indicates whether the script should remove the identified orphaned GPOs.

        .EXAMPLE
            Get-OrphanedGPOs -RemoveOrphanGPOs $True

        .INPUTS
            None. You cannot pipe objects to this script.

        .OUTPUTS
            System.String. Outputs the names of orphaned GPOs or the results of deletion actions.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADObject                           | ActiveDirectory
                Get-ChildItem                          | Microsoft.PowerShell.Management
                Get-GPO                                | GroupPolicy
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Error                            | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.3
            DateModified:    20/Feb/2024
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com

    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([String])]

    param(
        [Parameter(Mandatory = $false)]
        [bool]$RemoveOrphanGPOs = $false
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

        # Construct SYSVOL path and GPC DN
        $unc = '\\{0}\SYSVOL\{0}\Policies' -f $Variables.DnsFqdn
        $GPOPoliciesDN = 'CN=Policies,CN=System,{0}' -f $Variables.defaultNamingContext

    } #end Begin

    Process {
        # Get all GPOs from AD and remove CN=
        $gpos = Get-ADObject -LDAPFilter '(objectClass=groupPolicyContainer)' -SearchBase $GPOPoliciesDN |
            ForEach-Object { $_.Name.Replace('CN=', '') }

        # Get all GPTs from SYSVOL
        $gpts = Get-ChildItem -Path $unc -Directory |
            Where-Object { $_.Name -ne 'PolicyDefinitions' } |
            ForEach-Object { $_.Name }

        # Find orphaned GPOs
        $OrphanedGPOs = $gpos | Where-Object { $_ -notin $gpts }

        Write-Verbose '"Found {0} Orphaned GPOs"' -f $OrphanedGPOs.Count
        Write-Verbose $OrphanedGPOs

        # Option to remove orphaned GPOs
        if ($RemoveOrphanGPOs) {
            $OrphanedGPOs | ForEach-Object {
                $gpoGuid = [Guid]$_
                $gpo = Get-GPO -Guid $gpoGuid
                if ($PSCmdlet.ShouldProcess($gpo.DisplayName, 'Delete')) {
                    Write-Verbose 'Deleting Orphaned GPO: {0}' -f $gpo.DisplayName
                    $gpo.Delete()
                } #end If
            } #end ForEach-Object
        } #end If
    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished getting and removing Orphan GPOs."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
