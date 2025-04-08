Function Start-DiskCleanup {
    <#
        .SYNOPSIS
            Comprehensive system cleanup utility.

        .DESCRIPTION
            Wrapper function to perform various system cleanup operations including:
            - Hibernation file removal
            - Recycle bin cleanup
            - Temporary folders cleanup
            - Windows image cleanup
            - System restore points
            - User profiles
            - Windows update cache
            - CCM cache
            - Error reports
            - Windows logs
            - Delivery optimization files

            Requires administrative privileges.

        .PARAMETER IncludeAll
            Include all cleanup parameters.

        .PARAMETER DisableHibernation
            Disable hibernation and remove hiberfil.sys.

        .PARAMETER RecycleBin
            Empty RecycleBin.

        .EXAMPLE
            Start-DiskCleanup -IncludeAll
            Performs all available cleanup operations.

        .EXAMPLE
            Start-DiskCleanup -RecycleBin -Folders -Verbose
            Cleans recycle bin and temporary folders with detailed progress.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success        : Boolean indicating overall success
                SpaceRecovered : Amount of space freed in bytes
                OperationsRun  : Count of operations performed
                Errors         : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Join-Path                                  ║ Microsoft.PowerShell.Management
                Test-Path                                  ║ Microsoft.PowerShell.Management
                Start-Process                              ║ Microsoft.PowerShell.Management
                Get-PSDrive                                ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                Write-Progress                             ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS
                Clear-RecycleBin                           ║ EguibarIT.HousekeepingPS
                Clear-TemporaryFile                        ║ EguibarIT.HousekeepingPS
                Clear-WindowsLog                           ║ EguibarIT.HousekeepingPS
                Clear-UserProfile                          ║ EguibarIT.HousekeepingPS
                Clear-WindowsUpdate                        ║ EguibarIT.HousekeepingPS
                Clear-ErrorReport                          ║ EguibarIT.HousekeepingPS
                Clear-DeliveryOptimizationFile             ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.3
            DateModified:    8/Apr/2025
            Author:         Vicente Rodriguez Eguibar
                           vicente@eguibar.com
                           Eguibar IT

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS

    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    [OutputType([PSCustomObject])]

    Param (

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Include all cleanup parameters',
            ParameterSetName = 'FullCleanup',
            Position = 0)]
        [switch]
        $IncludeAll,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Disable hibernation and remove the hiberfil.sys file',
            ParameterSetName = 'IndividualCleanup',
            Position = 1)]
        [switch]
        $DisableHibernation,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Empty RecycleBin',
            ParameterSetName = 'IndividualCleanup',
            Position = 2)]
        [switch]
        $RecycleBin,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Remove all files within defined folders.',
            ParameterSetName = 'IndividualCleanup',
            Position = 3)]
        [switch]
        $Folders,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Cleanup Online image using DSIM',
            ParameterSetName = 'IndividualCleanup',
            Position = 4)]
        [switch]
        $Image,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete all existing System Restore Points',
            ParameterSetName = 'IndividualCleanup',
            Position = 5)]
        [switch]
        $SystemRestorePoints,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Remove unused profiles',
            ParameterSetName = 'IndividualCleanup',
            Position = 6)]
        [switch]
        $Profiles,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete SoftwareDistribution folder used by Windows Update',
            ParameterSetName = 'IndividualCleanup',
            Position = 7)]
        [switch]
        $WindowsUpdate,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete System Center Configuration Manager local files',
            ParameterSetName = 'IndividualCleanup',
            Position = 8)]
        [switch]
        $CCM,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete Error Report (dump) files',
            ParameterSetName = 'IndividualCleanup',
            Position = 9)]
        [switch]
        $ErrorReport,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear Windows Logs (Not event viewer)',
            ParameterSetName = 'IndividualCleanup',
            Position = 10)]
        [switch]
        $WindowsLogs,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear temporary files',
            ParameterSetName = 'IndividualCleanup',
            Position = 11)]
        [switch]
        $TempFiles,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear Delivery Optimization files',
            ParameterSetName = 'IndividualCleanup',
            Position = 12)]
        [switch]
        $DeliveryOptimization
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
            Success        = $false
            SpaceRecovered = 0
            OperationsRun  = 0
            Errors         = @()
        }

        # Get initial free space
        $initialFreeSpace = (Get-PSDrive $env:SystemDrive[0]).Free
        Write-Debug -Message ('Initial free space: {0:N2} GB' -f ($initialFreeSpace / 1GB))

        # Enable all operations if IncludeAll is specified
        if ($IncludeAll) {
            Write-Verbose -Message 'Full cleanup selected'
            $PSBoundParameters['DisableHibernation'] = $true
            $PSBoundParameters['RecycleBin'] = $true
            $PSBoundParameters['Folders'] = $true
            $PSBoundParameters['Image'] = $true
            $PSBoundParameters['SystemRestorePoints'] = $true
            $PSBoundParameters['Profiles'] = $true
            $PSBoundParameters['WindowsUpdate'] = $true
            $PSBoundParameters['CCM'] = $true
            $PSBoundParameters['ErrorReport'] = $true
            $PSBoundParameters['WindowsLogs'] = $true
            $PSBoundParameters['TempFiles'] = $true
            $PSBoundParameters['DeliveryOptimization'] = $true
        } #end If

    } #end Begin

    Process {

        # Track total operations
        $totalOperations = ($PSBoundParameters.Keys | Where-Object { $_ -ne 'Verbose' -and $_ -ne 'Debug' }).Count
        $currentOperation = 0


        try {
            # Disable Hibernation
            if ($DisableHibernation) {
                $currentOperation++
                Write-Progress -Activity 'System Cleanup' -Status 'Disabling Hibernation' `
                    -PercentComplete (($currentOperation / $totalOperations) * 100)

                $hibernationFile = Join-Path -Path $env:SystemDrive -ChildPath 'hiberfil.sys'
                if (Test-Path -Path $hibernationFile -PathType Leaf) {

                    if ($PSCmdlet.ShouldProcess('Hibernation', 'Disable')) {

                        try {

                            $powerCfg = Join-Path -Path $env:SystemRoot -ChildPath 'System32\powercfg.exe'
                            $process = Start-Process -FilePath $powerCfg -ArgumentList '-h OFF' `
                                -Wait -NoNewWindow -PassThru -Verb RunAs

                            if ($process.ExitCode -eq 0) {

                                Write-Debug -Message 'Hibernation disabled successfully'
                                $result.OperationsRun++

                            } else {

                                throw "Process exited with code: $($process.ExitCode)"

                            } #end If-else

                        } catch {

                            $errorMsg = "Failed to disable hibernation: $($_.Exception.Message)"
                            Write-Warning -Message $errorMsg
                            $result.Errors += $errorMsg

                        } #end try-catch

                    } #end If
                } #end If
            } #end If

            # Process each cleanup operation
            $cleanupOperations = @(
                @{ Name = 'RecycleBin'; Function = 'Clear-RecycleBin' }
                @{ Name = 'TemporaryFiles'; Function = 'Clear-TemporaryFile' }
                @{ Name = 'WindowsLogs'; Function = 'Clear-WindowsLog' }
                @{ Name = 'UserProfiles'; Function = 'Clear-UserProfile'; Args = @{ ProfileAge = 65 } }
                @{ Name = 'WindowsUpdate'; Function = 'Clear-WindowsUpdate' }
                @{ Name = 'ErrorReports'; Function = 'Clear-ErrorReport' }
                @{ Name = 'DeliveryOptimization'; Function = 'Clear-DeliveryOptimizationFile' }
            )

            foreach ($operation in $cleanupOperations) {

                if ($PSBoundParameters[$operation.Name]) {

                    $currentOperation++
                    Write-Progress -Activity 'System Cleanup' -Status "Running $($operation.Name)" `
                        -PercentComplete (($currentOperation / $totalOperations) * 100)

                    if ($PSCmdlet.ShouldProcess($operation.Name, 'Cleanup')) {

                        try {
                            $params = @{}
                            if ($operation.Args) {

                                $params = $operation.Args

                            } #end If

                            $cleanupResult = & $operation.Function @params
                            if ($cleanupResult.Success) {

                                $result.OperationsRun++
                                Write-Debug -Message ('{0} completed successfully' -f $operation.Name)

                            } else {

                                $result.Errors += $cleanupResult.Errors

                            } #end If-else

                        } catch {

                            $errorMsg = "Failed to run $($operation.Name): $($_.Exception.Message)"
                            Write-Warning -Message $errorMsg
                            $result.Errors += $errorMsg

                        } #end try-catch

                    } #end If

                } #end If

            } #end foreach

            # Special handling for DISM cleanup
            if ($Image) {

                $currentOperation++
                Write-Progress -Activity 'System Cleanup' -Status 'Running Image Cleanup' `
                    -PercentComplete (($currentOperation / $totalOperations) * 100)

                if ($PSCmdlet.ShouldProcess('Windows Image', 'Cleanup')) {

                    try {

                        if ([Environment]::OSVersion.Version -lt (New-Object 'Version' 6, 2)) {

                            $process = Start-Process -FilePath 'dism.exe' `
                                -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup' `
                                -Wait -NoNewWindow -PassThru

                            if ($process.ExitCode -eq 0) {

                                $result.OperationsRun++

                            }#end If

                        } else {

                            $process = Start-Process -FilePath 'dism.exe' `
                                -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup /ResetBase' `
                                -Wait -NoNewWindow -PassThru

                            if ($process.ExitCode -eq 0) {

                                $result.OperationsRun++

                            } #end If

                        } #end If-else

                    } catch {

                        $errorMsg = "Image cleanup failed: $($_.Exception.Message)"
                        Write-Warning -Message $errorMsg
                        $result.Errors += $errorMsg

                    } #end try-catch

                } #end If

            } #end If

            # Calculate space recovered
            $finalFreeSpace = (Get-PSDrive $env:SystemDrive[0]).Free
            $result.SpaceRecovered = $finalFreeSpace - $initialFreeSpace
            $result.Success = ($result.OperationsRun -gt 0 -and $result.Errors.Count -eq 0)

        } catch {

            $errorMsg = "Cleanup failed: $($_.Exception.Message)"
            Write-Error -Message $errorMsg
            $result.Errors += $errorMsg

        } finally {

            Write-Progress -Activity 'System Cleanup' -Completed

        } #end try-catch-finally

    } #end Process

    End {
        Write-Verbose -Message ('Recovered: {0:N2} GB, Operations: {1}, Errors: {2}' -f
            ($result.SpaceRecovered / 1GB), $result.OperationsRun, $result.Errors.Count)

        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'disk cleanup.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Start-DiskCleanup
