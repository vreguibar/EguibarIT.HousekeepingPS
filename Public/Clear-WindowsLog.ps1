function Clear-WindowsLog {
    <#
        .SYNOPSIS
            Clear Windows log files safely.

        .DESCRIPTION
            This function safely clears Windows log files by properly handling the TrustedInstaller
            service and providing detailed progress information. It requires administrative privileges.

        .EXAMPLE
            Clear-WindowsLog
            Cleans Windows logs with default settings.

        .EXAMPLE
            Clear-WindowsLog -Verbose
            Cleans Windows logs with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success      : Boolean indicating if operation completed successfully
                LogsCleared : Number of log files cleared
                BytesFreed  : Amount of space freed in bytes
                Errors     : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-Process                                ║ Microsoft.PowerShell.Management
                Stop-Process                               ║ Microsoft.PowerShell.Management
                Remove-Item                                ║ Microsoft.PowerShell.Management
                Get-Service                                ║ Microsoft.PowerShell.Management
                Start-Service                              ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS

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
            Success     = $false
            LogsCleared = 0
            BytesFreed  = 0
            Errors      = @()
        }

        # Define log paths to clear
        $logPaths = @(
            Join-Path -Path $env:SystemDrive -ChildPath 'Windows\Logs'
            Join-Path -Path $env:SystemRoot -ChildPath 'Logs'
            Join-Path -Path $env:SystemRoot -ChildPath 'ServiceProfiles\LocalService\AppData\Local\Temp'
        )

    } #end Begin

    Process {

        try {
            Write-Verbose -Message 'Stopping TrustedInstaller service...'
            $trustedInstaller = Get-Service -Name TrustedInstaller -ErrorAction Stop

            if ($trustedInstaller.Status -eq 'Running') {

                if ($PSCmdlet.ShouldProcess('TrustedInstaller', 'Stop Service')) {

                    $process = Get-Process -Name TrustedInstaller -ErrorAction SilentlyContinue

                    if ($process) {
                        Stop-Process -InputObject $process -Force -ErrorAction Stop
                    } #end If

                    $trustedInstaller.WaitForStatus('Stopped', '00:00:30')
                } #end If

            } #end If

            # Process each log path
            foreach ($path in $logPaths) {

                if (Test-Path -Path $path) {

                    Write-Verbose -Message ('Processing log path: {0}' -f $path)
                    $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue

                    if ($files) {

                        $totalFiles = $files.Count
                        $processedCount = 0

                        foreach ($file in $files) {

                            $processedCount++
                            $message = ('Removing {0}' -f $file.FullName)

                            Write-Progress -Activity 'Clearing Windows Logs' `
                                -Status $message `
                                -PercentComplete (($processedCount / $totalFiles) * 100)

                            if ($PSCmdlet.ShouldProcess($message, 'Remove Log File')) {

                                try {

                                    $fileSize = $file.Length
                                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                    $result.LogsCleared++
                                    $result.BytesFreed += $fileSize

                                } catch {

                                    $errorMsg = ('Failed to remove {0}: {1}' -f
                                        $file.Name, $_.Exception.Message)
                                    Write-Warning -Message $errorMsg
                                    $result.Errors += $errorMsg

                                } #end try-catch

                            } #end If

                        } #end foreach

                    } #end If

                } else {

                    Write-Debug -Message ('Log path not found: {0}' -f $path)

                } #end If
            } #end foreach

        } catch {

            $errorMsg = ('Error clearing logs: {0}' -f $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg

        } finally {

            # Ensure TrustedInstaller is running
            Write-Verbose -Message 'Restarting TrustedInstaller service...'

            try {

                Start-Service -Name TrustedInstaller -ErrorAction Stop
                $trustedInstaller.WaitForStatus('Running', '00:00:30')

            } catch {

                $errorMsg = 'Failed to restart TrustedInstaller service'
                Write-Warning -Message $errorMsg
                $result.Errors += $errorMsg

            } #end try-catch

            Write-Progress -Activity 'Clearing Windows Logs' -Completed
        } #end try-catch-finally

        $result.Success = ($result.LogsCleared -gt 0 -and $result.Errors.Count -eq 0)

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'clear Windows Logs.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-WindowsLog
