function Clear-UserProfiles {
    <#
        .Synopsis
            Delete User Profiles.
        .DESCRIPTION
            Find and delete User Profiles
        .EXAMPLE
            Clear-UserProfiles
        .EXAMPLE
            Clear-UserProfiles 40
        .EXAMPLE
            Clear-UserProfiles -ProfileAge 40
        .PARAMETER ProfileAge
            Integer representing the amount of days to define the age of any given profile.
        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-WMIObject                          | Microsoft.PowerShell.Management
    #>
    [CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = 'Medium')]
    [OutputType([bool])]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $false,
            HelpMessage = 'Profile Age. Days since last usage. Default to 90 if not given,',
            ParameterSetName = 'IndividualCleanup',
            Position = 10)]
        [int]
        $ProfileAge
    )

    Begin {
        if (-not $ProfileAge) {
            $ProfileAge = 90
        }
    } #end Begin

    Process {
        $AllProfiles = Get-WmiObject Win32_UserProfile |
            Where-Object {
                $_.localpath -notlike '*systemprofile' -and
                $_.localpath -notlike '*Administrator' -and
                $_.localpath -notlike '*NetworkService' -and
                $_.localpath -notlike '*LocalService' -and
                $_.localpath -notlike "*$env:USERNAME" -and
                $_.loaded -eq $false
            }

        foreach ($Item in $AllProfiles) {
            try {
                $LastUsed = $Item.ConvertToDateTime($Item.LastUseTime)
            } Catch {
                # if listed in WMI but without any properties (as in; no LastUseTime)...catch the time error:
                Write-Verbose -Message ('Orphaned record found: {0}' -f ($($Item.Localpath) - $($Item.SID)))
                $Item.Delete()
            } Finally {
                if ($LastUsed -lt (Get-Date).AddDays(-$ProfileAge)) {
                    Write-Verbose -Message ('Deleting: {0} - Last used on {1}' -f $Item.LocalPath, $LastUsed)
                    $Item.Delete()
                } else {
                    Write-Verbose -Message ('Skipping: {0} - Last used on {1}' -f $Item.LocalPath, $LastUsed)
                } #end If
            } #end Try-Catch-Finally
        } #end ForEach

    } #end Process

    End {
    } #end End
}
