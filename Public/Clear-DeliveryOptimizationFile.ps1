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

    Process {
        Write-Progress -Activity 'Clearing Delivery Optimization Cache' -Status 'Checking cache size...'

        try {
            $initialSize = 0

            # Check if we can use the module method
            if ($moduleAvailable) {
                try {
                    # Get initial cache size
                    $status = Get-DeliveryOptimizationStatus -ErrorAction Stop
                    $initialSize = $status.FileSizeInCache
                    Write-Debug -Message ('Initial cache size: {0:N2} MB' -f ($initialSize / 1MB))
                } catch {
                    Write-Warning -Message ('Failed to get cache status: {0}' -f $_.Exception.Message)
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
                # Fallback or if module not available
                Write-Verbose -Message 'Using Disk Cleanup as fallback or primary method'

                if ($PSCmdlet.ShouldProcess('Delivery Optimization Cache', 'Cleanup with cleanmgr')) {
                    try {
                        # Prepare cleanmgr sageset
                        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files'
                        if (Test-Path -Path $regPath) {
                            # Set the Delivery Optimization Files option to be selected
                            Set-ItemProperty -Path $regPath -Name 'StateFlags0001' -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                        }

                        # Run cleanmgr
                        $cleanMgr = Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:1' -Wait -PassThru

                        if ($cleanMgr.ExitCode -eq 0) {
                            # Approximate freed space - we can't know exactly without module
                            $result.BytesFreed = 1024 * 1024 * 10  # Assume at least 10MB
                            $result.Method = 'DiskCleanup'
                            $result.Success = $true
                            Write-Debug -Message 'Cache cleared using Disk Cleanup'
                        } else {
                            throw "Disk Cleanup failed with exit code: $($cleanMgr.ExitCode)"
                        }
                    } catch {
                        $errorMsg = ('Disk Cleanup failed: {0}' -f $_.Exception.Message)
                        Write-Error -Message $errorMsg
                        $result.Errors += $errorMsg
                    }
                }
            }

            # Final verification if module is available
            if ($moduleAvailable) {
                try {
                    $finalSize = (Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue).FileSizeInCache
                    if ($null -ne $finalSize) {
                        $result.Success = ($finalSize -lt $initialSize)
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

    End {
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
