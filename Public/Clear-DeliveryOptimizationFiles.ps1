function Clear-DeliveryOptimizationFiles {
    <#
        .Synopsis
            Delete Delivery Optimization Files files.
        .DESCRIPTION
            Find and delete Delivery Optimization Files files
        .EXAMPLE
            Clear-DeliveryOptimizationFiles
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-DeliveryOptimizationStatus         | DeliveryOptimization
                Delete-DeliveryOptimizationCache       | DeliveryOptimization
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param ()

    Begin {
    } #end Begin

    Process {
        try {
            [int]$CacheBytes = (Get-DeliveryOptimizationStatus -ErrorAction Stop).FileSizeInCache
            Delete-DeliveryOptimizationCache -Force -ErrorAction Stop
            Write-Verbose -Message ('Purged {0} MB from Delivery Optimization cache' -f ([math]::Round($CacheBytes / 1mb, 1)))
        } catch {
            Write-Verbose -Message 'Unable to purge from Delivery Optimization cache with PowerShell.  Trying Disk Cleanup Manager'
        }
    } #end Process

    End {
    } #end End
}
