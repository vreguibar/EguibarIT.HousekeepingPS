function Clear-CCMcache {
    <#
        .SYNOPSIS
            Cleans the Configuration Manager (CCM) client cache.

        .DESCRIPTION
            This function removes cached content from the Configuration Manager (SCCM/CCM) client cache.
            It uses the UIResource.UIResourceMgr COM object to properly clean the cache through the CCM API.
            If the CCM client is not present, it checks for orphaned cache folders.

            The function requires administrative privileges to access the CCM client.

        .PARAMETER Force
            If specified, suppresses confirmation prompts. Use with caution.

        .EXAMPLE
            Clear-CCMcache
            Cleans the CCM cache on the local machine.

        .EXAMPLE
            Clear-CCMcache -Verbose
            Cleans the CCM cache with detailed progress information.

        .EXAMPLE
            Clear-CCMcache -Force
            Cleans the CCM cache without prompting for confirmation.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success      : Boolean indicating if operation completed successfully
                CacheSize    : Size of cache before cleaning (in bytes)
                ItemsCleared : Number of cache items removed
                Message      : Operation details or error message

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-CimInstance                            ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
            https://docs.microsoft.com/en-us/mem/configmgr/core/clients/manage/manage-clients
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'If specified, suppresses confirmation prompts. Use with caution.'
        )]
        [switch]$Force
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module Import

        ##############################
        # Variables Definition

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            CacheSize    = 0
            ItemsCleared = 0
            Message      = ''
            Errors       = @()
        }

        # Cache folder path
        [string]$cachePath = Join-Path -Path $env:SystemDrive -ChildPath 'Windows\ccmcache'

        # Initialize variables we'll be using
        $UIResourceMgr = $null
        $Cache = $null
        $CacheElements = $null
    } #end Begin

    Process {
        try {
            Write-Debug -Message 'Checking for CCM client installation...'

            # Check if CCM client is installed using CimInstance
            $ccmClient = Get-CimInstance -Namespace 'root\ccm' -ClassName 'SMS_Client' -ErrorAction Stop

            if ($ccmClient) {
                Write-Verbose -Message 'CCM client found. Starting cache cleanup...'

                # Calculate initial cache size
                if (Test-Path -Path $cachePath) {
                    try {
                        $initialSize = (Get-ChildItem -Path $cachePath -Recurse -File -ErrorAction SilentlyContinue |
                                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        if ($null -eq $initialSize) {
                            $initialSize = 0
                        }
                        $result.CacheSize = $initialSize
                        Write-Debug -Message ('Initial cache size: {0:N2} MB' -f ($initialSize / 1MB))
                    } catch {
                        Write-Debug -Message "Error calculating cache size: $($_.Exception.Message)"
                        # Just continue if we can't calculate the cache size
                    }
                } #end if

                # Initialize COM object with error handling
                try {
                    $UIResourceMgr = New-Object -ComObject 'UIResource.UIResourceMgr'
                    $Cache = $UIResourceMgr.GetCacheInfo()
                    $CacheElements = $Cache.GetCacheElements()

                    $totalItems = $CacheElements.Count
                    Write-Verbose -Message ('Found {0} items in CCM cache' -f $totalItems)

                    # If no items, set success but with zero items
                    if ($totalItems -eq 0) {
                        $result.Success = $true
                        $result.Message = 'Cache is already empty'
                        return $result
                    }

                    foreach ($Element in $CacheElements) {
                        $message = ('Delete cache element: ID={0}, Location={1}' -f
                            $Element.ContentID, $Element.Location)

                        if ($Force -or $PSCmdlet.ShouldProcess($message, 'Clear CCM Cache')) {
                            try {
                                $Cache.DeleteCacheElement($Element.CacheElementID)
                                $result.ItemsCleared++
                                Write-Debug -Message ('Successfully deleted: {0}' -f $Element.Location)
                            } catch {
                                $errorMsg = ('Failed to delete {0}: {1}' -f
                                    $Element.ContentID, $_.Exception.Message)
                                Write-Warning -Message $errorMsg
                                $result.Errors += $errorMsg
                            } #end try-catch
                        } #end if

                        if ($totalItems -gt 0) {
                            Write-Progress -Activity 'Clearing CCM Cache' -Status $message `
                                -PercentComplete (($result.ItemsCleared / $totalItems) * 100)
                        }
                    } #end foreach

                    $result.Success = $true
                    $result.Message = ('Successfully cleared {0} cache items' -f $result.ItemsCleared)

                } catch {
                    throw ('Failed to initialize CCM cache management: {0}' -f $_.Exception.Message)
                } #end try-catch

            } else {
                Write-Warning -Message 'CCM client not found'
                $result.Message = 'CCM client not installed'
            } #end if-else

        } catch {
            if (Test-Path -Path $cachePath) {
                $warning = 'CCM cache folder exists but client is not properly installed'
                Write-Warning -Message $warning
                $result.Message = $warning
            } else {
                $info = 'No CCM client or cache folder found'
                Write-Verbose -Message $info
                $result.Message = $info
            } #end if-else

            Write-Error -Message ('Error processing CCM cache: {0}' -f $_.Exception.Message)
            $result.Errors += $_.Exception.Message
        } finally {
            # Clean up COM objects safely
            if ($null -ne $UIResourceMgr) {
                try {
                    # Only try to release if it's a real COM object
                    if ($UIResourceMgr.GetType().FullName -eq '__ComObject') {
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($UIResourceMgr) | Out-Null
                    }
                } catch {
                    # Just absorb any errors here
                    Write-Debug -Message "Error releasing COM object: $($_.Exception.Message)"
                }

                # This is always safe
                $UIResourceMgr = $null
            }

            # Request garbage collection
            [System.GC]::Collect()

            Write-Progress -Activity 'Clearing CCM Cache' -Completed
        } #end try-catch-finally
    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'clearing CCM Cache.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-CCMcache
