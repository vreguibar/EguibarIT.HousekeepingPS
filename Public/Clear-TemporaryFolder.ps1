function Clear-TemporaryFolder {
    <#
        .SYNOPSIS
            Delete files from temporary folders on the system.

        .DESCRIPTION
            This function removes files and folders from various temporary locations on the system.
            It includes system temp folders, user temp folders, and Windows upgrade folders.
            Requires administrative privileges to access system folders.

        .PARAMETER FoldersToClean
            Array of additional folders to clean. Default folders are always included.
            Pipeline input is supported.

        .EXAMPLE
            Clear-TemporaryFolders
            Cleans all default temporary folders.

        .EXAMPLE
            Clear-TemporaryFolders -Verbose
            Cleans folders with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success       : Boolean indicating if all operations completed successfully
                FoldersCleared: Number of folders processed
                BytesFreed    : Amount of space freed in bytes
                Errors       : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Test-Path                                  ║ Microsoft.PowerShell.Management
                Get-ChildItem                              ║ Microsoft.PowerShell.Management
                Remove-Item                                ║ Microsoft.PowerShell.Management
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
        ConfirmImpact = 'Medium'
    )]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Include all folders to cleanup',
            Position = 0)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        $FoldersToClean = [System.Collections.ArrayList]::new()
    )

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
            Success        = $false
            FoldersCleared = 0
            BytesFreed     = 0
            Errors         = @()
        }

        # Default folders to clean
        $defaultFolders = @(
            "$env:Temp\*",
            "$env:SystemDrive\Windows\Temp\*",
            "$env:SystemDrive\Windows\Prefetch\*",
            "$env:SystemDrive\Windows\Downloaded Program Files\*",
            "$env:SystemDrive\Users\*\AppData\Local\Temp\*",
            "$env:SystemDrive\Users\*\AppData\LocalLow\Temp\*"
        )

        # Windows upgrade folders
        $upgradefolders = @(
            '$INPLACE.~TR',
            '$Windows.~BT',
            '$Windows.~LS',
            '$Windows.~WS',
            '$Windows.~Q',
            '$Windows.~TR',
            '$Windows.old',
            'ESD'
        ) | ForEach-Object { Join-Path -Path $env:SystemDrive -ChildPath $_ }

        # Add default folders if not already included
        foreach ($folder in $defaultFolders + $upgradefolders) {
            if (-not $FoldersToClean.Contains($folder)) {
                [void]$FoldersToClean.Add($folder)
            } #end If
        } #end ForEach

        Write-Debug -Message ('Total folders to process: {0}' -f $FoldersToClean.Count)

    } #end Begin

    Process {
        $totalFolders = $FoldersToClean.Count
        $currentFolder = 0

        foreach ($folderPath in $FoldersToClean) {

            $currentFolder++
            Write-Progress -Activity 'Cleaning Temporary Folders' `
                -Status ('Processing {0}' -f $folderPath) `
                -PercentComplete (($currentFolder / $totalFolders) * 100)

            if (Test-Path -Path $folderPath) {

                try {
                    # Get folder size before deletion
                    $folderSize = (Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction Stop |
                            Measure-Object -Property Length -Sum).Sum

                    if ($PSCmdlet.ShouldProcess($folderPath, 'Delete Folder')) {
                        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction Stop
                        $result.FoldersCleared++
                        $result.BytesFreed += $folderSize
                        Write-Debug -Message ('Deleted: {0} ({1:N2} MB)' -f $folderPath, ($folderSize / 1MB))
                    } #end If

                } catch {

                    $errorMsg = ('Error deleting {0}: {1}' -f $folderPath, $_.Exception.Message)
                    Write-Warning -Message $errorMsg
                    $result.Errors += $errorMsg

                } #end try-catch

            } else {

                Write-Debug -Message ('Path not found: {0}' -f $folderPath)

            } #end if-else

        } #end foreach

        # Success should be based on whether we had errors, not whether folders were found
        $result.Success = ($result.Errors.Count -eq 0)

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'clear temporary folders.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-TemporaryFolder
