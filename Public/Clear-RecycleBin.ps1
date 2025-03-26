Function Clear-RecycleBin {
    <#
        .Synopsis
            Clear RecycleBin
        .DESCRIPTION
            Empty RecycleBin
        .EXAMPLE
            Clear-RecycleBin
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                New-Object                             | Microsoft.PowerShell.Utility
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'low')]
    [OutputType([bool])]

    param ()

    Write-Verbose -Message 'Empty RecycleBin'
    $Recycler = (New-Object -ComObject Shell.Application).NameSpace(0xa)
    $Recycler.items() | ForEach-Object { Remove-Item $_.path -Force -Recurse }
}
