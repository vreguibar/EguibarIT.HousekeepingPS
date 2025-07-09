function Clear-TemporaryFile {
    <#
        .SYNOPSIS
            Delete temporary files from the system.

        .DESCRIPTION
            This function searches for and removes temporary files from specified locations.
            It handles various temporary file types including .tmp, .dmp, .etl, .edb, and log files.
            Requires administrative privileges to access system folders.

        .PARAMETER Force
            If specified, suppresses confirmation prompts. Use with caution.

        .EXAMPLE
            Clear-TemporaryFile
            Removes temporary files with default settings.

        .EXAMPLE
            Clear-TemporaryFile -Verbose
            Removes temporary files with detailed progress information.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success      : Boolean indicating if operation completed successfully
                FilesRemoved : Number of files removed
                BytesFreed   : Amount of space freed in bytes
                Errors      : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-ChildItem                              ║ Microsoft.PowerShell.Management
                Remove-Item                                ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                Test-Path                                  ║ Microsoft.PowerShell.Management
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS

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

    param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
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
        }

        # Initialize result object
        $result = [PSCustomObject]@{
            Success      = $false
            FilesRemoved = 0
            BytesFreed   = 0
            Errors       = @()
        }

        # Define cleanup locations and patterns
        $cleanupPaths = @(
            @{
                Path        = $env:TEMP
                Description = 'User temporary files'
                Recursive   = $true
            },
            @{
                Path        = $env:windir + '\Temp'
                Description = 'Windows temporary files'
                Recursive   = $true
            },
            @{
                Path        = $env:SystemDrive + '\Temp'
                Description = 'System drive temp folder'
                Recursive   = $true
            }
        )

        $FileExtensions = @(
            '*.tmp',
            '*.dmp',
            '*.etl',
            '*.edb',
            'thumbcache*.db',
            '*.log'
        )

    } #end Begin

    Process {

        foreach ($location in $cleanupPaths) {
            Write-Verbose -Message ('Processing {0}' -f $location.Description)

            try {
                # Verify path exists
                if (-not (Test-Path -Path $location.Path -PathType Container)) {
                    Write-Debug -Message ('Path not found: {0}' -f $location.Path)
                    continue
                } #end if

                # Get all matching files with proper error handling for junction points
                $files = @()
                try {
                    if ($location.Recursive) {
                        # Use safer recursion with junction point handling
                        $files = Get-ChildItem -Path $location.Path -Include $FileExtensions -File -Recurse `
                            -Force -ErrorAction SilentlyContinue | 
                            Where-Object { $_.LinkType -ne 'Junction' -and $_.LinkType -ne 'SymbolicLink' }
                    } else {
                        $files = Get-ChildItem -Path $location.Path -Include $FileExtensions -File `
                            -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    Write-Warning -Message ('Error accessing {0}: {1}' -f $location.Path, $_.Exception.Message)
                    continue
                }
                
                $totalFiles = ($files | Measure-Object).Count

                if ($totalFiles -gt 0) {

                    Write-Debug -Message ('Found {0} files in {1}' -f $totalFiles, $location.Path)
                    $processedCount = 0

                    foreach ($file in $files) {

                        $processedCount++
                        $message = ('Removing {0}' -f $file.FullName)

                        Write-Progress -Activity ('Cleaning {0}' -f $location.Description) `
                            -Status $message `
                            -PercentComplete (($processedCount / $totalFiles) * 100)

                        if ($Force -or $PSCmdlet.ShouldProcess($message, 'Remove File')) {

                            try {

                                $fileSize = $file.Length
                                Remove-Item -Path $file.FullName -Force -ErrorAction Stop

                                $result.FilesRemoved++
                                $result.BytesFreed += $fileSize

                                Write-Debug -Message ('Removed: {0}' -f $file.FullName)

                            } catch {

                                $errorMsg = ('Failed to remove {0}: {1}' -f
                                    $file.Name, $_.Exception.Message)
                                Write-Warning -Message $errorMsg
                                $result.Errors += $errorMsg

                            } #end try-catch

                        } #end if

                    } #end foreach

                } else {

                    Write-Debug -Message ('No matching files found in {0}' -f $location.Path)

                } #end if-else

            } catch {

                $errorMsg = ('Error processing {0}: {1}' -f
                    $location.Description, $_.Exception.Message)
                Write-Error -Message $errorMsg
                $result.Errors += $errorMsg

            } finally {

                Write-Progress -Activity ('Cleaning {0}' -f $location.Description) -Completed

            } #end try-catch-finally

        } #end foreach

        # Success should be based on whether we had errors, not whether files were found
        $result.Success = ($result.Errors.Count -eq 0)

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'clear temporary files.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-TemporaryFile
