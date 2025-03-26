function Clear-ErrorReports {
    <#
        .Synopsis
            Find and delete error report files.
        .DESCRIPTION
            Find all error report (dump files) on System Drive and delete them.
        .EXAMPLE
            Clear-ErrorReports
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Remove-Item                            | Microsoft.PowerShell.Management
                Get-ChildItem                          | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'low')]
    [OutputType([bool])]

    param ()

    try {
        Get-ChildItem -Path $env:SystemDrive\*.dmp -Recurse -ErrorAction Continue | Remove-Item -Force
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error -Message '[ERROR] Item Not Found.'
    }

    try {
        Get-ChildItem -Path $env:ALLUSERSPROFILE\Microsoft\Windows\WER\ | Remove-Item -Recurse -Force
    } catch [System.IO.IOException] {
        Write-Error -Message '[ERROR] Unknown exception.'
    }

} #end function Clear-ErrorReports
