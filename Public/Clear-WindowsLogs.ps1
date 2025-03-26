function Clear-WindowsLogs {
    <#
        .Synopsis
            Delete Log files.
        .DESCRIPTION
            Find and delete log files
        .EXAMPLE
            Clear-WindowsLogs
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-Process                            | Microsoft.PowerShell.Management
                Stop-Process                           | Microsoft.PowerShell.Management
                Remove-Item                            | Microsoft.PowerShell.Management
                Get-Service                            | Microsoft.PowerShell.Management
                Start-Service                          | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param ()

    Begin {
    } #end Begin

    Process {
        try {
            #Cleanup windows logs
            Get-Process -Name TrustedInstaller -ErrorAction SilentlyContinue | Stop-Process -Confirm:$false -Force -ErrorAction SilentlyContinue

            Remove-Item -Recurse $env:systemdrive\Windows\logs\* -Confirm:$false -Force -ErrorAction SilentlyContinue

            while ((Get-Service TrustedInstaller).Status -ne 'Running') {
                Start-Service TrustedInstaller
            }

        } catch [System.IO.IOException] {
        }
    } #end Process

    End {
    } #end End
}
