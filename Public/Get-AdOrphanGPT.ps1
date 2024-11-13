Function Get-AdOrphanGPT {

    <#
        .SYNOPSIS
            Finds and optionally removes orphaned Group Policy Templates (GPTs) in SYSVOL.

        .DESCRIPTION
            Searches for GPT folders within the SYSVOL directory and compares them against
            GPOs listed in Active Directory to identify and optionally remove orphaned GPTs.

        .PARAMETER RemoveOrphanGPT
            Switch to specify whether to remove orphaned GPT directories if found.

        .OUTPUTS
            [string[]] Array of orphaned GPTs.

        .EXAMPLE
            Get-AdOrphanGPT -RemoveOrphanGPT $true

        .NOTES
            Version:         1.4
            DateModified:    12/Nov/2024
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com

        .NOTES
            Used Functions:
                Name                         | Module
                -----------------------------|--------------------------
                Get-Module                   | Microsoft.PowerShell.Core
                Import-Module                | Microsoft.PowerShell.Core
                New-Object                   | Microsoft.PowerShell.Utility
                Get-ChildItem                | Microsoft.PowerShell.Management
                Remove-Item                  | Microsoft.PowerShell.Management
                Write-Verbose                | Microsoft.PowerShell.Utility
                Write-Output                 | Microsoft.PowerShell.Utility
                Write-Error                  | Microsoft.PowerShell.Utility
                Get-FunctionDisplay          | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]

    Param (

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'If present will remove any Orphan GPT.',
            Position = 0)]
        [switch]
        $RemoveOrphanGPT

    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        Import-MyModule ActiveDirectory -Force -Verbose:$false


        ##############################
        # Variables Definition

        # Construct SYSVOL path and GPC DN
        $unc = '\\{0}\SYSVOL\{0}\Policies' -f $Variables.DnsFqdn
        $GPOPoliciesDN = 'CN=Policies,CN=System,{0}' -f $Variables.defaultNamingContext

        $gpos = [System.Collections.Generic.List[object]]::New()
        $gpts = [System.Collections.Generic.List[object]]::New()
    } #end Begin

    process {
        try {
            #$gpoc = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$GPOPoliciesDN")
            $gpoc = [System.DirectoryServices.DirectoryEntry]::New("LDAP://$GPOPoliciesDN")
            $store = $gpoc.Children

            foreach ($gpo in $store) {
                $gpos.Add($gpo.Name.Replace('CN=', ''))
            } #end Foreach

            $gpoc.Dispose()

            # Retrieve GPT directories from SYSVOL
            $dirs = Get-ChildItem -Path $unc -Directory

            foreach ($dir in $dirs) {
                if (-not $dir.Name.Contains('PolicyDefinitions')) {
                    $gpts.Add($dir.Name)
                } #end If
            } #end Foreach

            # Identify orphaned GPTs
            $OrphanedGPTs = $gpts.ToArray() | Where-Object { $_ -notin $gpos.ToArray() }

            Write-Verbose -Message ('Found {0} Orphaned GPTs' -f $OrphanedGPTs.Count)
            Write-Output $OrphanedGPTs

            # Remove orphaned GPTs if -RemoveOrphanGPT is specified and confirmed
            if ($RemoveOrphanGPT -and $OrphanedGPTs.Count -gt 0) {
                foreach ($gptDir in $OrphanedGPTs) {
                    Write-Verbose -Message ('Deleting orphan GPT: {0}' -f $gptDir)
                    Remove-Item -Path "$unc\$gptDir" -Recurse -Force
                } #end Foreach
            } #end If
        } catch {
            Write-Error -Message ('An error occurred while processing orphaned GPTs: {0}' -f $_.Exception.Message)
            throw
        } #end Try-Catch

    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'getting and removing Orphan GPTs.'
        )
        Write-Verbose -Message $txt
    } #end End
}
