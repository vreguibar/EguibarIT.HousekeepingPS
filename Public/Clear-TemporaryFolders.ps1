function Clear-TemporaryFolders {
    <#
        .Synopsis
            Delete files on temporary folders.
        .DESCRIPTION
            Find and delete files on temporary folders
        .EXAMPLE
            Clear-TemporaryFolders
        .PARAMETER FoldersToClean
            Array including all folders to clean up.
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Test-Path                              | Microsoft.PowerShell.Management
                Get-ChildItem                          | Microsoft.PowerShell.Management
                Remove-Item                            | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Include all folders to cleanup',
            Position = 0)]
        [System.Collections.ArrayList]
        $foldersToClean
    )

    Begin {

        #Ensure defaults folders are included
        If (-not $foldersToClean.Contains("$env:Temp\*")) {
            $foldersToClean.Add("$env:Temp\*")
        }
        If (-not $foldersToClean.Contains("$env:systemDrive\Windows\Temp\*")) {
            $foldersToClean.Add("$env:systemDrive\Windows\Temp\*")
        }
        If (-not $foldersToClean.Contains("$env:systemDrive\Windows\PrefETCH\*")) {
            $foldersToClean.Add("$env:systemDrive\Windows\PrefETCH\*")
        }
        If (-not $foldersToClean.Contains("$env:systemDrive\Windows\Downloaded Progam Files\*")) {
            $foldersToClean.Add("$env:systemDrive\Windows\Downloaded Progam Files\*")
        }
        If (-not $foldersToClean.Contains("$env:systemDrive\Users\*\AppData\Local\Temp\*")) {
            $foldersToClean.Add("$env:systemDrive\Users\*\AppData\Local\Temp\*")
        }
        If (-not $foldersToClean.Contains("$env:systemDrive\Users\*\AppData\LocalLow\Temp\*")) {
            $foldersToClean.Add("$env:systemDrive\Users\*\AppData\LocalLow\Temp\*")
        }

        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$INPLACE.~TR'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$INPLACE.~TR'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~BT'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~BT'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~LS'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~LS'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~WS'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~WS'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~Q'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~Q'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~TR'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.~TR'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.old'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath '$Windows.old'))
        }
        If (-not $foldersToClean.Contains((Join-Path -Path $env:SystemDrive -ChildPath 'ESD'))) {
            $foldersToClean.Add((Join-Path -Path $env:SystemDrive -ChildPath 'ESD'))
        }

    } #end Begin

    Process {
        foreach ($folderToCheck in $foldersToClean) {
            If (Test-Path -Path $folderToCheck) {
                Try {
                    Remove-Item -Path $folderToCheck -Recurse -Force -ErrorAction Continue
                    Write-Verbose -Message ('Deleted: {0}' -f $folderToCheck)
                } Catch {
                    Write-Error -Message ('Error deleting: {0}' -f $folderToCheck) -Exception $($_.Exception.Message)
                }
            } #end If
        } #end ForEach
    } #end Process

    End {
    } #end End
}
