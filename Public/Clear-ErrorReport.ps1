function Clear-ErrorReport {
    <#
        .SYNOPSIS
            Find and delete error report files and dump files.

        .DESCRIPTION
            This function searches for and removes Windows error reports and memory dump files
            from the system drive and Windows Error Reporting (WER) folders. It handles both
            standard dump files (*.dmp) and Windows Error Reporting data.

            Requires administrative privileges to access system folders.

        .EXAMPLE
            Clear-ErrorReport
            Removes all error reports and dump files from standard locations.

        .EXAMPLE
            Clear-ErrorReport -Verbose
            Removes error reports with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success        : Boolean indicating operation success
                FilesRemoved  : Number of files removed
                BytesFreed    : Amount of space freed
                Errors       : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                      ║ Module/Namespace
                ══════════════════════════════════════════╬══════════════════════════════
                Remove-Item                               ║ Microsoft.PowerShell.Management
                Get-ChildItem                             ║ Microsoft.PowerShell.Management
                Write-Verbose                             ║ Microsoft.PowerShell.Utility
                Write-Warning                             ║ Microsoft.PowerShell.Utility
                Write-Error                               ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                       ║ EguibarIT.HousekeepingPS

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
        }

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            FilesRemoved = 0
            BytesFreed   = 0
            Errors       = @()
        }

        # Define cleanup locations
        $cleanupPaths = @(
            @{
                Path        = Join-Path -Path $env:SystemDrive -ChildPath '*.dmp'
                Description = 'System dump files'
                Recurse     = $true
            },
            @{
                Path        = Join-Path -Path $env:ALLUSERSPROFILE -ChildPath 'Microsoft\Windows\WER'
                Description = 'Windows Error Reporting files'
                Recurse     = $true
            }
        )

    } #end Begin

    Process {

        foreach ($location in $cleanupPaths) {
            Write-Verbose -Message ('Processing {0}' -f $location.Description)

            try {
                # Get files to be removed and calculate total size
                $files = Get-ChildItem -Path $location.Path -Recurse:$location.Recurse -File -ErrorAction Stop

                if ($files) {
                    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
                    $fileCount = $files.Count

                    Write-Debug -Message ('Found {0} files totaling {1:N2} MB' -f
                        $fileCount, ($totalSize / 1MB))

                    # Process each file
                    $processedCount = 0
                    foreach ($file in $files) {
                        $processedCount++

                        $message = ('Removing {0}' -f $file.FullName)
                        Write-Debug -Message $message

                        if ($PSCmdlet.ShouldProcess($message, 'Remove File')) {

                            try {

                                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                $result.FilesRemoved++
                                $result.BytesFreed += $file.Length

                            } catch {

                                $errorMsg = ('Failed to remove {0}: {1}' -f
                                    $file.FullName, $_.Exception.Message)
                                Write-Warning -Message $errorMsg
                                $result.Errors += $errorMsg

                            } #end try-catch

                        } #end if

                        # Update progress
                        Write-Progress -Activity ('Cleaning {0}' -f $location.Description) `
                            -Status $message `
                            -PercentComplete (($processedCount / $fileCount) * 100)
                    } #end foreach

                } else {

                    Write-Debug -Message ('No files found in {0}' -f $location.Path)

                } #end if-else

            } catch {

                $errorMsg = ('Error processing {0}: {1}' -f
                    $location.Description, $_.Exception.Message)
                Write-Error -Message $errorMsg
                $result.Errors += $errorMsg

            } #end try-catch

            Write-Progress -Activity ('Cleaning {0}' -f $location.Description) -Completed
        } #end foreach

        $result.Success = ($result.FilesRemoved -gt 0 -and $result.Errors.Count -eq 0)

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'removing Error reports.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-ErrorReports
