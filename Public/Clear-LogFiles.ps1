funtion clear-LogFiles {

    <#
        .Synopsis
            Find and delete Log files.
        .DESCRIPTION
            Find and delete all log files within a time range.
        .EXAMPLE
            clear-LogFiles
        .EXAMPLE
            clear-LogFiles c:\Logs 45
        .EXAMPLE
            clear-LogFiles -Directory c:\Logs -Days 45
        .EXAMPLE
            $Splat = @{
                Directory = 'c:\Logs'
                Days      = 45
            }
            clear-LogFiles @Splat
        .PARAMETER Directory
            Directory to search for LOG files
        .PARAMETER Days
            Number of days old to search for files. Default is 30.
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ChildItem                          | Microsoft.PowerShell.Management
                Remove-Item                            | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Directory to search for LOG files',
            Position = 0)]
        [string]
        $Directory,

        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Number of days old to search for files. Default is 30.',
            Position = 0)]
        [int]
        $Days
    )

    Begin {

        #Check if parameter empty. Set default value.
        If (-not $Directory) {
            $directory = 'C:\Windows\Powershell_transcriptlog'
        } #end If

        #Number of days.
        If (-not $Days) {
            $Days = 30
        } #end If

        $thresholdDate = (Get-Date).AddDays(-$Days)
    } #end Begin

    Process {
        # Get files in the directory
        $files = Get-ChildItem -Path $directory | Where-Object { !$_.PSIsContainer }

        foreach ($file in $files) {
            $creationDate = $file.CreationTime

            # Compare creation date with threshold date
            if ($creationDate -lt $thresholdDate) {
                # Delete the file
                Remove-Item -Path $file.FullName -Force
                Write-Verbose -Message ('Deleted file: {0}' -f $($file.FullName))
            } #end If
        } #end Foreach
    } #end Process

    End {

    } #end End
} #end Function
