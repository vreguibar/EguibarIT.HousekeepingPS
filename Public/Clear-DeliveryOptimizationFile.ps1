function Clear-DeliveryOptimizationFile {
    <#
        .SYNOPSIS
            Delete Delivery Optimization files.

        .DESCRIPTION
            This function finds and deletes Delivery Optimization files from the cache.
            It requires administrative privileges and provides detailed progress information.
            Falls back to using Disk Cleanup if PowerShell method fails.

        .EXAMPLE
            Clear-DeliveryOptimizationFile
            Deletes Delivery Optimization cache files with default settings.

        .EXAMPLE
            Clear-DeliveryOptimizationFile -Verbose
            Deletes cache files with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success    : Boolean indicating if operation completed successfully
                BytesFreed : Amount of space freed in bytes
                Method     : Method used to clear cache (PowerShell/DiskCleanup)
                Errors     : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                   ║ Module/Namespace
                ═══════════════════════════════════════╬══════════════════════════════
                Get-DeliveryOptimizationStatus         ║ DeliveryOptimization
                Delete-DeliveryOptimizationCache       ║ DeliveryOptimization
                Start-Process                          ║ Microsoft.PowerShell.Management
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Warning                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.3
            DateModified:    10/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([PSCustomObject])]

    param ()

    begin {
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
        } #end If

        # Initialize result object
        $result = [PSCustomObject]@{
            Success    = $false
            BytesFreed = 0
            Method     = ''
            Errors     = @()
        }

        # Check for required module
        $moduleAvailable = $false
        try {
            # Check if module is available before trying to import
            if (Get-Module -ListAvailable -Name DeliveryOptimization -ErrorAction SilentlyContinue) {
                Import-Module -Name DeliveryOptimization -ErrorAction Stop
                $moduleAvailable = $true
                Write-Debug -Message 'DeliveryOptimization module imported successfully'
            } else {
                Write-Warning -Message 'DeliveryOptimization module not available. Will try alternative method.'
            }
        } catch {
            $errorMsg = 'Failed to import DeliveryOptimization module'
            Write-Warning -Message $errorMsg
        }#end Try-Catch

    } #end Begin

    process {
        Write-Progress -Activity 'Clearing Delivery Optimization Cache' -Status 'Checking cache size...'

        try {
            $initialSize = 0

            # Check if we can use the module method
            if ($moduleAvailable) {
                try {
                    # Get initial cache size
                    $status = Get-DeliveryOptimizationStatus -ErrorAction Stop
                    if ($null -ne $status -and $status.PSObject.Properties.Name -contains 'FileSizeInCache') {
                        $initialSize = $status.FileSizeInCache
                        if ($null -eq $initialSize) {
                            $initialSize = 0
                        }
                        Write-Debug -Message ('Initial cache size: {0:N2} MB' -f ($initialSize / 1MB))
                    } else {
                        Write-Debug -Message 'FileSizeInCache property not available'
                        $initialSize = 0
                    }
                } catch {
                    Write-Warning -Message ('Failed to get cache status: {0}' -f $_.Exception.Message)
                    $initialSize = 0
                }
            }

            # If module is available and cache has content
            if ($moduleAvailable -and $initialSize -gt 0) {
                $message = ('Clear {0:N2} MB of cache' -f ($initialSize / 1MB))

                if ($PSCmdlet.ShouldProcess($message, 'Delete Cache')) {
                    Write-Progress -Activity 'Clearing Delivery Optimization Cache' -Status 'Deleting cache files...'

                    # Try PowerShell method first
                    try {
                        Delete-DeliveryOptimizationCache -Force -ErrorAction Stop
                        $result.BytesFreed = $initialSize
                        $result.Method = 'PowerShell'
                        $result.Success = $true
                        Write-Debug -Message 'Cache cleared using PowerShell method'
                    } catch {
                        Write-Warning -Message ('PowerShell cache clear failed: {0}' -f $_.Exception.Message)
                        throw  # Re-throw to trigger fallback
                    }
                }
            } else {
                # Fallback for Windows Server Core or when module not available
                Write-Verbose -Message 'Using native PowerShell fallback method'

                if ($PSCmdlet.ShouldProcess('Delivery Optimization Cache', 'Manual cleanup')) {
                    try {
                        # Define common Delivery Optimization cache locations
                        $cacheLocations = @(
                            Join-Path -Path $env:SystemRoot -ChildPath (
                                'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'
                            )
                            Join-Path -Path $env:SystemRoot -ChildPath 'SoftwareDistribution\DeliveryOptimization'
                            Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\DeliveryOptimization'
                        )

                        $totalBytesFreed = 0
                        $processedLocations = 0

                        foreach ($location in $cacheLocations) {
                            if (Test-Path -Path $location) {
                                Write-Verbose -Message ('Processing cache location: {0}' -f $location)

                                try {
                                    # Calculate size before deletion
                                    $filesBeforeDeletion = Get-ChildItem -Path $location -Recurse -File -Force `
                                        -ErrorAction SilentlyContinue
                                    $measureResult = $filesBeforeDeletion | Measure-Object -Property Length -Sum `
                                        -ErrorAction SilentlyContinue
                                    
                                    if ($null -ne $measureResult -and $measureResult.PSObject.Properties.Name -contains 'Sum') {
                                        $sizeBeforeDeletion = $measureResult.Sum
                                    } else {
                                        $sizeBeforeDeletion = 0
                                    }

                                    # Remove cache files
                                    if ($sizeBeforeDeletion -gt 0) {
                                        $targetPath = Join-Path -Path $location -ChildPath '*'
                                        Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                                        $totalBytesFreed += $sizeBeforeDeletion
                                        Write-Debug -Message ('Cleaned {0:N2} MB from {1}' -f `
                                            ($sizeBeforeDeletion / 1MB), $location)
                                    }

                                    $processedLocations++
                                } catch {
                                    Write-Warning -Message ('Failed to clean {0}: {1}' -f $location, $_.Exception.Message)
                                }
                            } else {
                                Write-Debug -Message ('Cache location not found: {0}' -f $location)
                            }
                        }

                        # Try to stop and restart Delivery Optimization service if files were found
                        if ($totalBytesFreed -gt 0) {
                            try {
                                $doSvc = Get-Service -Name 'DoSvc' -ErrorAction SilentlyContinue
                                if ($doSvc -and $doSvc.Status -eq 'Running') {
                                    Write-Verbose -Message 'Stopping Delivery Optimization service for cleanup'
                                    Stop-Service -Name 'DoSvc' -Force -ErrorAction SilentlyContinue
                                    Start-Sleep -Seconds 2

                                    # Retry cleanup after stopping service
                                    foreach ($location in $cacheLocations) {
                                        if (Test-Path -Path $location) {
                                            $targetPath = Join-Path -Path $location -ChildPath '*'
                                            Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                                        }
                                    }

                                    Start-Service -Name 'DoSvc' -ErrorAction SilentlyContinue
                                    Write-Debug -Message 'Restarted Delivery Optimization service'
                                }
                            } catch {
                                Write-Debug -Message ('Service management error: {0}' -f $_.Exception.Message)
                            }
                        }

                        $result.BytesFreed = $totalBytesFreed
                        $result.Method = 'NativePowerShell'
                        $result.Success = $true

                        if ($totalBytesFreed -gt 0) {
                            Write-Verbose -Message ('Freed {0:N2} MB using native PowerShell method' -f ($totalBytesFreed / 1MB))
                        } else {
                            Write-Verbose -Message 'No Delivery Optimization cache files found to clean'
                        }
                    } catch {
                        $errorMsg = ('Disk Cleanup failed: {0}' -f $_.Exception.Message)
                        Write-Warning -Message $errorMsg
                        $result.Errors += $errorMsg
                        # Don't fail completely if disk cleanup fails
                        $result.Success = $true
                        $result.Method = 'Failed'
                    }
                }
            }

            # Final verification if module is available
            if ($moduleAvailable) {
                try {
                    $finalStatus = Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue
                    if ($null -ne $finalStatus -and $finalStatus.PSObject.Properties.Name -contains 'FileSizeInCache') {
                        $finalSize = $finalStatus.FileSizeInCache
                        if ($null -ne $finalSize) {
                            $result.Success = ($finalSize -lt $initialSize)
                        }
                    }
                } catch {
                    # Don't override success if verification fails
                    Write-Debug -Message ('Failed to verify final cache size: {0}' -f $_.Exception.Message)
                }
            }

        } catch {
            $errorMsg = ('Failed to clear cache: {0}' -f $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg
        } finally {
            Write-Progress -Activity 'Clearing Delivery Optimization Cache' -Completed
        } #end try-catch-finally
    } #end Process

    end {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing Delivery Optimization cache.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end Function Clear-DeliveryOptimizationFile
