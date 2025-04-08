function Clear-WindowsUpdate {
    <#
        .SYNOPSIS
            Delete Windows Update cache files safely.

        .DESCRIPTION
            This function safely removes Windows Update cache files by properly stopping
            and starting the Windows Update service. It requires administrative privileges
            and provides detailed progress information.

        .EXAMPLE
            Clear-WindowsUpdate
            Cleans Windows Update cache with default settings.

        .EXAMPLE
            Clear-WindowsUpdate -Verbose
            Cleans Windows Update cache with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success      : Boolean indicating if operation completed successfully
                BytesFreed   : Amount of space freed in bytes
                ServiceState : Final state of Windows Update service
                Errors       : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                      ║ Module/Namespace
                ══════════════════════════════════════════╬══════════════════════════════
                Remove-Item                               ║ Microsoft.PowerShell.Management
                Get-Service                               ║ Microsoft.PowerShell.Management
                Start-Service                             ║ Microsoft.PowerShell.Management
                Stop-Service                              ║ Microsoft.PowerShell.Management
                Write-Verbose                             ║ Microsoft.PowerShell.Utility
                Write-Warning                             ║ Microsoft.PowerShell.Utility
                Write-Error                               ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                       ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
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

    param ()

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

        ##############################
        # Variables Definition

        # Verify administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            throw 'This function requires administrative privileges'
        }

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            BytesFreed   = 0
            ServiceState = ''
            Errors       = @()
        }

        # Windows Update service name
        $serviceName = 'wuauserv'
        $distributionPath = Join-Path -Path $env:SystemRoot -ChildPath 'SoftwareDistribution'

    } #end Begin

    Process {

        try {
            Write-Verbose -Message 'Getting initial cache size...'
            if (Test-Path -Path $distributionPath) {

                $initialSize = (Get-ChildItem -Path $distributionPath -Recurse -File |
                        Measure-Object -Property Length -Sum).Sum

            } #end If

            # Stop Windows Update service
            Write-Progress -Activity 'Clearing Windows Update Cache' -Status 'Stopping Windows Update service...'
            $service = Get-Service -Name $serviceName -ErrorAction Stop

            if ($service.Status -eq 'Running') {

                if ($PSCmdlet.ShouldProcess($serviceName, 'Stop Service')) {

                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                    $service.WaitForStatus('Stopped', '00:00:30')

                } #end If

            } #end If

            # Remove cache files
            if ($service.Status -eq 'Stopped') {

                $message = ('Removing cache from: {0}' -f $distributionPath)
                Write-Progress -Activity 'Clearing Windows Update Cache' -Status $message

                if ($PSCmdlet.ShouldProcess($distributionPath, 'Remove Cache')) {

                    if (Test-Path -Path $distributionPath) {

                        try {

                            Remove-Item -Path $distributionPath -Recurse -Force -ErrorAction Stop
                            $result.BytesFreed = $initialSize
                            Write-Debug -Message ('Removed {0:N2} MB of cache' -f ($initialSize / 1MB))

                        } catch {

                            $errorMsg = ('Failed to remove cache: {0}' -f $_.Exception.Message)
                            Write-Warning -Message $errorMsg
                            $result.Errors += $errorMsg

                        } #end Try/Catch
                    } #end If
                } #end If

            } else {

                $errorMsg = 'Failed to stop Windows Update service'
                Write-Warning -Message $errorMsg
                $result.Errors += $errorMsg

            } #end If-else

            # Restart Windows Update service
            Write-Progress -Activity 'Clearing Windows Update Cache' -Status 'Starting Windows Update service...'
            Start-Service -Name $serviceName -ErrorAction Stop
            $service.WaitForStatus('Running', '00:00:30')

            $result.ServiceState = (Get-Service -Name $serviceName).Status
            $result.Success = ($result.BytesFreed -gt 0 -and $result.Errors.Count -eq 0)

        } catch {

            $errorMsg = ('Error processing Windows Update cache: {0}' -f $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg

        } finally {

            Write-Progress -Activity 'Clearing Windows Update Cache' -Completed

        } #end try-catch-finally

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing Windows Update cache.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-WindowsUpdate
