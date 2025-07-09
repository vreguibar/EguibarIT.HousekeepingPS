function Clear-WindowsServerCoreCleanup {
    <#
        .SYNOPSIS
            Enhanced cleanup operations optimized for Windows Server Core.

        .DESCRIPTION
            This function provides comprehensive cleanup operations specifically designed for
            Windows Server Core environments where GUI tools like cleanmgr.exe are not available.
            Uses native PowerShell and command-line tools only.

        .PARAMETER CleanupType
            Type of cleanup to perform: All, Cache, Temp, Logs, Updates, IIS, DNS

        .EXAMPLE
            Clear-WindowsServerCoreCleanup -CleanupType All
            Performs all available cleanup operations.

        .OUTPUTS
            [PSCustomObject] with cleanup results.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]

    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Cache', 'Temp', 'Logs', 'Updates', 'IIS', 'DNS')]
        [string[]]$CleanupType = 'All'
    )

    begin {
        $result = [PSCustomObject]@{
            Success       = $false
            BytesFreed    = 0
            OperationsRun = 0
            Errors        = @()
        }

        # Server Core specific cleanup locations
        $serverCoreCleanupPaths = @{
            'Temp'  = @(
                "$env:SystemRoot\Temp",
                "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\Temp",
                "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Temp"
            )
            'Cache' = @(
                "$env:SystemRoot\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache",
                "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\Microsoft\Windows\INetCache",
                "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\INetCache"
            )
            'Logs'  = @(
                "$env:SystemRoot\Logs",
                "$env:SystemRoot\System32\LogFiles",
                "$env:SystemRoot\System32\winevt\Logs\Archive"
            )
            'IIS'   = @(
                "$env:SystemRoot\System32\LogFiles\W3SVC*",
                "$env:SystemRoot\System32\LogFiles\HTTPERR",
                "$env:SystemRoot\inetpub\logs\LogFiles"
            )
            'DNS'   = @(
                "$env:SystemRoot\System32\dns\dns.log*"
            )
        }
    }

    process {
        foreach ($type in $CleanupType) {
            if ($type -eq 'All') {
                $typesToProcess = $serverCoreCleanupPaths.Keys
            } else {
                $typesToProcess = @($type)
            }

            foreach ($cleanupCategory in $typesToProcess) {
                if ($serverCoreCleanupPaths.ContainsKey($cleanupCategory)) {
                    Write-Verbose "Processing $cleanupCategory cleanup..."

                    foreach ($path in $serverCoreCleanupPaths[$cleanupCategory]) {
                        if (Test-Path $path) {
                            try {
                                $sizeBefore = (Get-ChildItem $path -Recurse -File -Force -ErrorAction SilentlyContinue |
                                        Measure-Object Length -Sum).Sum

                                if ($PSCmdlet.ShouldProcess($path, "Clean $cleanupCategory files")) {
                                    Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                                    $result.BytesFreed += $sizeBefore
                                    $result.OperationsRun++
                                }
                            } catch {
                                $result.Errors += "Failed to clean $path`: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        }

        $result.Success = ($result.OperationsRun -gt 0)
    }

    end {
        return $result
    }
}
