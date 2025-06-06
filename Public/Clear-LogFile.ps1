function Clear-LogFile {

    <#
        .SYNOPSIS
            Find and delete log files older than specified days.

        .DESCRIPTION
            This function searches for and deletes log files within a specified directory
            that are older than a given number of days. It supports filtering by file age
            and provides detailed progress information.

        .PARAMETER Directory
            Directory to search for log files. If not specified, defaults to
            'C:\Windows\Powershell_transcriptlog'.

        .PARAMETER Days
            Number of days to keep files. Files older than this will be deleted.
            Default is 30 days.

        .EXAMPLE
            Clear-LogFile
            Removes log files older than 30 days from default directory.

        .EXAMPLE
            Clear-LogFile -Directory 'C:\Logs' -Days 45 -Verbose
            Removes files older than 45 days from C:\Logs with detailed progress.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success      : Boolean indicating if all operations completed successfully
                FilesRemoved : Number of files removed
                BytesFreed  : Amount of space freed
                Errors      : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                   ║ Module/Namespace
                ═══════════════════════════════════════╬══════════════════════════════
                Get-ChildItem                          ║ Microsoft.PowerShell.Management
                Remove-Item                            ║ Microsoft.PowerShell.Management
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Warning                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS

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

    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Directory to search for LOG files',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Directory = 'C:\Windows\Powershell_transcriptlog',

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Number of days old to search for files. Default is 30.',
            Position = 1)]
        [ValidateRange(1, 3650)]
        [int]
        $Days = 30
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

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            FilesRemoved = 0
            BytesFreed   = 0
            Errors       = @()
        }

        # Calculate threshold date
        $thresholdDate = (Get-Date).AddDays(-$Days)
        Write-Debug -Message ('Threshold date set to: {0}' -f $thresholdDate)

        # Verify directory exists
        if (-not (Test-Path -Path $Directory -PathType Container)) {
            Write-Warning -Message ('Directory not found: {0}' -f $Directory)
            return $result
        } #end If

    } #end Begin

    Process {
        try {
            # Get all files in directory
            $files = Get-ChildItem -Path $Directory -File -ErrorAction Stop

            # Safely determine file count
            $totalFiles = 0
            if ($null -ne $files) {
                if ($files -is [System.Array]) {
                    $totalFiles = $files.Length
                } elseif ($files -is [System.IO.FileInfo]) {
                    # Single file returned
                    $totalFiles = 1
                    # Convert single item to array for consistent processing
                    $files = @($files)
                } else {
                    # No files found
                    $totalFiles = 0
                    $files = @()
                }
            }

            Write-Verbose -Message ('Found {0} files in {1}' -f $totalFiles, $Directory)

            if ($totalFiles -gt 0) {
                $processedCount = 0

                foreach ($file in $files) {
                    $processedCount++

                    # Update progress
                    Write-Progress -Activity 'Removing old log files' `
                        -Status ('Processing {0}' -f $file.Name) `
                        -PercentComplete (($processedCount / $totalFiles) * 100)

                    if ($file.CreationTime -lt $thresholdDate) {
                        $message = ('Remove file: {0}' -f $file.FullName)

                        if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove Log File')) {
                            try {
                                $fileSize = $file.Length
                                Remove-Item -Path $file.FullName -Force -ErrorAction Stop

                                $result.FilesRemoved++
                                $result.BytesFreed += $fileSize

                                Write-Debug -Message ('Removed file: {0}' -f $file.FullName)
                            } catch {
                                $errorMsg = ('Failed to remove {0}: {1}' -f
                                    $file.FullName, $_.Exception.Message)
                                Write-Warning -Message $errorMsg
                                $result.Errors += $errorMsg
                            } #end try-catch
                        } #end if
                    } else {
                        Write-Debug -Message ('Skipping file not older than threshold: {0}' -f $file.Name)
                    } #end if-else
                } #end foreach
            } #end if

            $result.Success = ($result.Errors.Count -eq 0)

        } catch {
            $errorMsg = ('Error processing directory {0}: {1}' -f
                $Directory, $_.Exception.Message)
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg
        } finally {
            Write-Progress -Activity 'Removing old log files' -Completed
        } #end try-catch-finally
    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing Log files.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end Function Clear-LogFile
