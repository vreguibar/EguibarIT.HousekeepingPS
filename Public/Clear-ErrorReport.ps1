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
                Recurse     = $false
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
                # Get files to be removed with error handling for access denied
                $files = @()

                # Handle wildcards vs folders differently
                if ($location.Path -match '\*') {
                    # Path with wildcards - use direct Get-ChildItem
                    $files = @(Get-ChildItem -Path $location.Path -File -ErrorAction SilentlyContinue)
                } else {
                    # Directory path - handle recursion and access denied errors
                    try {
                        # Test path first
                        if (Test-Path -Path $location.Path -PathType Container) {
                            # Use Get-ChildItem with ErrorVariable to capture access denied errors
                            $childItems = @()

                            # First level
                            $firstLevel = @(Get-ChildItem -Path $location.Path -File -ErrorAction SilentlyContinue -ErrorVariable accessErrors)
                            if ($firstLevel.Count -gt 0) {
                                $childItems += $firstLevel
                            }

                            # Handle recursion if needed
                            if ($location.Recurse) {
                                try {
                                    # Get subdirectories that we can access
                                    $subDirs = @(Get-ChildItem -Path $location.Path -Directory -ErrorAction SilentlyContinue)

                                    foreach ($dir in $subDirs) {
                                        try {
                                            $dirFiles = @(Get-ChildItem -Path $dir.FullName -File -Recurse -ErrorAction SilentlyContinue -ErrorVariable +accessErrors)
                                            if ($dirFiles.Count -gt 0) {
                                                $childItems += $dirFiles
                                            }
                                        } catch {
                                            # Log access errors but continue with other directories
                                            Write-Debug -Message ('Access denied to {0}: {1}' -f $dir.FullName, $_.Exception.Message)
                                        }
                                    }
                                } catch {
                                    # Handle overall recursion errors
                                    Write-Debug -Message ('Error during recursive search: {0}' -f $_.Exception.Message)
                                }
                            }

                            $files = $childItems
                        }
                    } catch {
                        # Log path access errors
                        Write-Debug -Message ('Cannot access path {0}: {1}' -f $location.Path, $_.Exception.Message)
                    }
                }

                # Process files if any were found
                $fileCount = ($files | Measure-Object).Count

                if ($fileCount -gt 0) {
                    $totalSize = 0
                    foreach ($file in $files) {
                        $totalSize += $file.Length
                    }

                    Write-Debug -Message ('Found {0} files totaling {1:N2} MB' -f
                        $fileCount, ($totalSize / 1MB))

                    # Process each file
                    $processedCount = 0
                    foreach ($file in $files) {
                        $processedCount++

                        $message = ('Removing {0}' -f $file.FullName)
                        Write-Debug -Message $message

                        if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove File')) {
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
                    Write-Debug -Message ('No accessible files found in {0}' -f $location.Path)
                } #end if-else

            } catch {
                $errorMsg = ('Error processing {0}: {1}' -f
                    $location.Description, $_.Exception.Message)
                Write-Warning -Message $errorMsg
                $result.Errors += $errorMsg
            } #end try-catch

            Write-Progress -Activity ('Cleaning {0}' -f $location.Description) -Completed
        } #end foreach

        # Success if at least one file was removed or there were no errors
        $result.Success = ($result.FilesRemoved -gt 0 -or $result.Errors.Count -eq 0)
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
} #end function Clear-ErrorReport
