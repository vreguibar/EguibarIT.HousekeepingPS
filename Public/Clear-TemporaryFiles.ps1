function Clear-TemporaryFiles {
    <#
        .Synopsis
            Delete temporary files.
        .DESCRIPTION
            Find and delete temporary files
        .EXAMPLE
            Clear-TemporaryFiles
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ChildItem                          | Microsoft.PowerShell.Management
                Remove-Item                            | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param ()

    Begin {
        $FileExtensions = [System.Collections.ArrayList]@(
            '*.tmp',
            '*.dmp',
            '*.etl',
            '*.edb',
            'thumbcache*.db',
            '*.log'
        )
    } #end Begin

    Process {
        Get-ChildItem -Path $env:systemDrive -Include $FileExtensions -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction Continue

    } #end Process

    End {
    } #end End
}
