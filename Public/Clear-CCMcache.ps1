function Clear-CCMcache {
    <#
        .Synopsis
            Delete CCM cache files.
        .DESCRIPTION
            Find and delete CCM cache files
        .EXAMPLE
            Clear-CCMcache
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-WmiObject                          | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param ()

    Begin {
    } #end Begin

    Process {
        try {
            if (Get-WmiObject -Namespace 'root\ccm' -Class 'SMS_Client' -ErrorAction Stop) {

                Write-Verbose -Message 'Starting CCM cache Cleanup...'
                $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
                $Cache = $UIResourceMgr.GetCacheInfo()
                $CacheElements = $Cache.GetCacheElements()

                foreach ($Element in $CacheElements) {
                    Write-Verbose -Message ('Deleting PackageID {0}} in folder {1}}' -f $Element.ContentID, $Element.Location)
                    $Cache.DeleteCacheElement($Element.CacheElementID)
                }
            }
        } catch {
            if (Test-Path "$env:SystemDrive\Windows\ccmcache") {
                Write-Verbose -Message 'No CM agent found in WMI but a cache folder is present. Cache will NOT be cleared!'
            } else {
                Write-Verbose -Message 'No CM agent found in WMI and no cache folder detected. Nothing to see here...moving along...'
            }
        }
    } #end Process

    End {
    } #end End
}
