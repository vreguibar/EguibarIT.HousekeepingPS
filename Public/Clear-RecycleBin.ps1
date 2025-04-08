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
            Version:         1.1
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(
        SupportsShouldProcess = $False,
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
        # Check if the Recycle Bin is empty
        try {
            Write-Verbose -Message 'Empty RecycleBin'

            # Use .NET approach instead of COM
            [System.IO.DirectoryInfo]$recycleBin = Get-ChildItem 'Shell:RecycleBinFolder' -Force
            $totalItems = ($recycleBin | Measure-Object).Count

            if ($totalItems -gt 0) {

                Write-Debug -Message ('Found {0} items in Recycle Bin' -f $totalItems)
                $processedCount = 0

                foreach ($item in $recycleBin) {

                    $processedCount++
                    $message = ('Removing {0}' -f $item.Name)

                    Write-Progress -Activity 'Emptying Recycle Bin' `
                        -Status $message `
                        -PercentComplete (($processedCount / $totalItems) * 100)

                    try {

                        $itemSize = $item.Length
                        Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop

                        $result.ItemsCleared++
                        $result.BytesFreed += $itemSize

                        Write-Debug -Message ('Removed: {0}' -f $item.FullName)

                    } catch {

                        $errorMsg = ('Failed to remove {0}: {1}' -f
                            $item.Name, $_.Exception.Message)
                        Write-Warning -Message $errorMsg
                        $result.Errors += $errorMsg

                    } #end try-catch
                } #end foreach

            } else {

                Write-Verbose -Message 'Recycle Bin is already empty'

            } #end if-else

            $result.Success = ($result.ItemsCleared -eq $totalItems)

        } catch {

            Write-Error -Message ('Failed to empty Recycle Bin: {0}' -f $_.Exception.Message)
            $result.Errors += $_.Exception.Message

        } finally {

            Write-Progress -Activity 'Emptying Recycle Bin' -Completed

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
