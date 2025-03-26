Function Start-DiskCleanup {
    <#
        .Synopsis
            Wrapper function for Disk Cleanup
        .DESCRIPTION
            Wrapper function used to delete some or all cleanup sections of a given disk
        .EXAMPLE
            Start-DiskCleanup -IncludeAll
        .EXAMPLE
            Start-DiskCleanup -RecycleBin -Folders
        .EXAMPLE
            $Splat = @{
                RecycleBin           = $true
                Folders              = $true
                Profiles             = $true
                WindowsUpdate        = $true
                ErrorReport          = $true
                WindowsLogs          = $true
                TempFiles            = $true
            }
            Start-DiskCleanup @Splat
        .PARAMETER IncludeAll
            Include all cleanup parameters
        .PARAMETER DisableHybernation
            Disable hybernation and remove the hiberfil.sys file
        .PARAMETER RecycleBin
            Empty RecycleBin
        .PARAMETER Folders
            Remove all files within defined folders.
        .PARAMETER Image
            Cleanup Online image using DSIM
        .PARAMETER SystemRestorePoints
            Delete all existing System Restore Points
        .PARAMETER Profiles
            Remove unused profiles
        .PARAMETER WindowsUpdate
            Delete SoftwareDistribution folder used by Windows Update
        .PARAMETER CCM
            Delete System Center Configuration Manager local files
        .PARAMETER ErrorReport
            Delete Error Report (dump) files
        .PARAMETER WindowsLogs
            Clear Windows Logs (Not event viewer)
        .PARAMETER TempFiles
            Clear temporary files
        .PARAMETER DeliveryOptimization
            Clear Delivery Optimization files
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Clear-RecycleBin                       | No Module - Individual Function
                Clear-ErrorReports                     | No Module - Individual Function
                Clear-TemporaryFolders                 | No Module - Individual Function
                Clear-TemporaryFiles                   | No Module - Individual Function
                Clear-WindowsLogs                      | No Module - Individual Function
                Clear-UserProfiles                     | No Module - Individual Function
                Clear-WindowsUpdate                    | No Module - Individual Function
                Clear-CCMcache                         | No Module - Individual Function
                Clear-DeliveryOptimizationFiles        | No Module - Individual Function

    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    Param (

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Include all cleanup parameters',
            ParameterSetName = 'FullCleanup',
            Position = 0)]
        [switch]
        $IncludeAll,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Disable hybernation and remove the hiberfil.sys file',
            ParameterSetName = 'IndividualCleanup',
            Position = 1)]
        [switch]
        $DisableHybernation,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Empty RecycleBin',
            ParameterSetName = 'IndividualCleanup',
            Position = 2)]
        [switch]
        $RecycleBin,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Remove all files within defined folders.',
            ParameterSetName = 'IndividualCleanup',
            Position = 3)]
        [switch]
        $Folders,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Cleanup Online image using DSIM',
            ParameterSetName = 'IndividualCleanup',
            Position = 4)]
        [switch]
        $Image,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete all existing System Restore Points',
            ParameterSetName = 'IndividualCleanup',
            Position = 5)]
        [switch]
        $SystemRestorePoints,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Remove unused profiles',
            ParameterSetName = 'IndividualCleanup',
            Position = 6)]
        [switch]
        $Profiles,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete SoftwareDistribution folder used by Windows Update',
            ParameterSetName = 'IndividualCleanup',
            Position = 7)]
        [switch]
        $WindowsUpdate,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete System Center Configuration Manager local files',
            ParameterSetName = 'IndividualCleanup',
            Position = 8)]
        [switch]
        $CCM,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Delete Error Report (dump) files',
            ParameterSetName = 'IndividualCleanup',
            Position = 9)]
        [switch]
        $ErrorReport,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear Windows Logs (Not event viewer)',
            ParameterSetName = 'IndividualCleanup',
            Position = 10)]
        [switch]
        $WindowsLogs,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear temporary files',
            ParameterSetName = 'IndividualCleanup',
            Position = 11)]
        [switch]
        $TempFiles,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Clear Delivery Optimization files',
            ParameterSetName = 'IndividualCleanup',
            Position = 12)]
        [switch]
        $DeliveryOptimization
    )

    Begin {

        if ($IncludeAll) {
            Write-Verbose -Message 'Full cleanup is selected.'
            $DisableHybernation = $true
            $RecycleBin = $true
            $Folders = $true
            $Image = $true
            $SystemRestorePoints = $true
            $Profiles = $true
            $WindowsUpdate = $true
            $CCM = $true
            $ErrorReport = $true
            $WindowsLogs = $true
            $TempFiles = $true
            $DeliveryOptimization = $true
        }

        $FreeSpaceGB = (Get-PSDrive $env:SystemDrive[0]).free / 1GB

        Write-Verbose -Message ('Free space {0:N2} GB' -f $FreeSpaceGB)

    } #end Begin

    Process {

        If ($DisableHybernation) {
            $File = (Join-Path -Path $env:SystemDrive -ChildPath 'hiberfil.sys')

            If (Test-Path -Path $File -PathType Leaf) {

                try {
                    Start-Process -FilePath (Join-Path -Path $env:SystemRoot -ChildPath 'System32\powercfg.exe') -ArgumentList '-h OFF' -Wait -ErrorAction Stop -NoNewWindow -Verb RunAs
                    Write-Verbose -Message ('Disabling Windows Hibernation and deleting the file {0} succeeded' -f $File)
                } catch {
                    Write-Verbose -Message ('Disabling Windows Hibernation and deleting the file {0} failed' -f $File)
                }
            } Else {
                Write-Verbose -Message 'Windows Hibernation is not enabled.  Nothing to do.'
            }
        } #end If

        If ($RecycleBin) {
            Clear-RecycleBin
        } #end If

        If ($Folders) {
            $foldersToClean = [System.Collections.ArrayList]@(
                "$env:Temp\*",
                "$env:systemDrive\Windows\Temp\*",
                "$env:systemDrive\Windows\PrefETCH\*",
                "$env:systemDrive\Windows\Downloaded Progam Files\*",
                "$env:systemDrive\Users\*\AppData\Local\Temp\*",
                "$env:systemDrive\Users\*\AppData\LocalLow\Temp\*"
            )

            Clear-TemporaryFolders -foldersToClean $foldersToClean
        } #end If

        If ($TempFiles) {
            Clear-TemporaryFiles
        }

        If ($WindowsLogs) {
            Clear-WindowsLogs
        }

        If ($Image) {
            if ([Environment]::OSVersion.Version -lt (New-Object 'Version' 6, 2)) {

                Invoke-Expression 'dism.exe /Online /Cleanup-Image /StartComponentCleanup'
                Invoke-Expression 'Dism.exe /online /Cleanup-Image /SpSuperseded'

            } else {

                Invoke-Expression 'Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase'

            }
        } #end If

        If ($SystemRestorePoints) {
            #Invoke-Expression "vssadmin.exe Delete Shadows /ALL /Quiet"
            $Splat = @{
                FilePath     = "$env:SystemRoot\System32\VSSadmin.exe"
                ArgumentList = 'Delete Shadows', "/For=$env:SystemDrive", '/Oldest /Quiet'
                Verb         = 'RunAs'
                Wait         = $true
                WindowStyle  = 'Hidden'
                ErrorAction  = 'SilentlyContinue'
                PassThru     = $true
            }
            Start-Process @Splat
        } #end If

        If ($Profiles) {
            Clear-UserProfiles -ProfileAge 65
        } #end If

        If ($WindowsUpdate) {
            Clear-WindowsUpdate
        } #end If

        If ($CCM) {
            Clear-CCMcache
        } #end If

        If ($ErrorReport) {
            Clear-ErrorReports
        }

        If ($DeliveryOptimization) {
            Clear-DeliveryOptimizationFiles
        }
    } #end Process

    End {
        Write-Verbose -Message ('Recovered space {0:N2} GB' -f ($FreeSpaceGB - ((Get-PSDrive $env:SystemDrive[0]).free / 1GB)))
    } #end End
} #end function Start-DiskCleanup
