Function Clear-RecycleBin {
    <#
        .SYNOPSIS
            Empties the Windows Recycle Bin.

        .DESCRIPTION
            This function empties the Windows Recycle Bin using the Shell.Application COM object.
            It provides progress information and detailed results of the operation.
            Requires appropriate permissions to access and modify the Recycle Bin.

        .EXAMPLE
            Clear-RecycleBin
            Empties the Recycle Bin with default settings.

        .EXAMPLE
            Clear-RecycleBin -Verbose
            Empties the Recycle Bin with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success     : Boolean indicating if operation completed successfully
                ItemsCleared: Number of items removed
                BytesFreed : Amount of space freed
                Errors     : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Remove-Item                                ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
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

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            ItemsCleared = 0
            BytesFreed   = 0
            Errors       = @()
        }

    } #end Begin

    Process {
        try {
            Write-Verbose -Message 'Empty RecycleBin'

            # Use Shell.Application to access Recycle Bin
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0xA) # 0xA is the Recycle Bin

            # Get an estimate of items in the recycle bin
            # This is a rough estimate as we can't directly count items
            $initialSize = 0
            $itemCount = 0

            # Try to enumerate items to get a count and total size
            $items = $recycleBin.Items()
            if ($items) {
                foreach ($item in $items) {
                    $itemCount++
                    try {
                        $initialSize += $item.Size
                    } catch {
                        # Some items may not report size
                        Write-Debug -Message ('Could not get size for item: {0}' -f $item.Name)
                    }
                }
            }

            Write-Debug -Message ('Found approximately {0} items in Recycle Bin' -f $itemCount)

            if ($PSCmdlet.ShouldProcess('Recycle Bin', 'Empty')) {
                # Get initial disk space info
                $drive = Get-PSDrive $env:SystemDrive[0]
                $initialFree = $drive.Free

                try {
                    # Empty the Recycle Bin
                    $recycleBin.Items() | ForEach-Object {
                        Write-Debug -Message ('Removing item from Recycle Bin: {0}' -f $_.Name)
                    }

                    # Use the built-in command
                    $shell.Namespace(0xA).InvokeVerb('EmptyRecycleBin')

                    # Get final disk space info to calculate space freed
                    $drive = Get-PSDrive $env:SystemDrive[0]
                    $finalFree = $drive.Free
                    $bytesFreed = $finalFree - $initialFree

                    # Update result
                    $result.BytesFreed = $bytesFreed
                    $result.ItemsCleared = $itemCount
                    $result.Success = $true

                    Write-Debug -Message ('Freed {0:N2} MB by emptying Recycle Bin' -f ($bytesFreed / 1MB))
                } catch {
                    $errorMsg = ('Failed to empty Recycle Bin: {0}' -f $_.Exception.Message)
                    Write-Warning -Message $errorMsg
                    $result.Errors += $errorMsg
                }
            } else {
                Write-Verbose -Message 'Operation cancelled by user'
            }

        } catch {
            $errorMsg = ('Failed to access Recycle Bin: {0}' -f $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg
        } finally {
            # Release COM object
            if ($null -ne $shell) {
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
            }
            [System.GC]::Collect()
        } #end try-catch-finally
    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'empty Recycle Bin.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end Function Clear-RecycleBin
