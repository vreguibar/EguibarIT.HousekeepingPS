function Clear-WindowsUpdate {
    <#
        .Synopsis
            Delete Windows Update files.
        .DESCRIPTION
            Find and delete Windows Update files
        .EXAMPLE
            Clear-WindowsUpdate
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Remove-Item                            | Microsoft.PowerShell.Management
                Get-Service                            | Microsoft.PowerShell.Management
                Start-Service                          | Microsoft.PowerShell.Management
                Stop-Service                           | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param ()

    Begin {
    } #end Begin

    Process {
        Stop-Service -Name wuauserv -Force

        while ((Get-Service -Name wuauserv).status -ne 'Stopped') {
            Write-Verbose -Message ('Deleting {0}\SoftwareDistribution]...' -f $env:SystemRoot)
            Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
        }

        if ((Get-Service -Name wuauserv).status -ne 'Running') {
            Write-Verbose -Message 'Starting Windows Update service...'
            Start-Service -Name wuauserv
        }

    } #end Process

    End {
    } #end End
}
