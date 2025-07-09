function Clear-UserProfile {
    <#
        .SYNOPSIS
            Delete unused user profiles from the system.

        .DESCRIPTION
            This function finds and deletes user profiles that haven't been used for a specified
            number of days. It excludes system profiles and currently loaded profiles.
            Requires administrative privileges.

        .PARAMETER ProfileAge
            Number of days since last use before a profile is considered for deletion.
            Default is 90 days.

        .EXAMPLE
            Clear-UserProfile
            Deletes profiles not used in the last 90 days.

        .EXAMPLE
            Clear-UserProfile -ProfileAge 30 -Verbose
            Deletes profiles not used in the last 30 days with detailed output.

        .OUTPUTS
            [PSCustomObject] with properties:
                Success         : Boolean indicating if operation completed successfully
                ProfilesRemoved : Number of profiles removed
                BytesFreed     : Amount of space freed in bytes
                Errors         : Array of error messages if any occurred

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-CimInstance                            ║ Microsoft.PowerShell.Management
                Remove-CimInstance                         ║ Microsoft.PowerShell.Management
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
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
        ConfirmImpact = 'High'
    )]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Profile Age. Days since last usage. Default to 90 if not given,',
            Position = 0)]
        [ValidateRange(1, 3650)]
        [PSDefaultValue(Help = 'Default Value is "90"',
            Value = 90
        )]
        [Alias('Age', 'Time', 'Days')]
        [int]
        $ProfileAge
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
            Success         = $false
            ProfilesRemoved = 0
            BytesFreed      = 0
            Errors          = @()
        }

        # Calculate cutoff date
        $cutoffDate = (Get-Date).AddDays(-$ProfileAge)
        Write-Debug -Message ('Profile age cutoff date: {0}' -f $cutoffDate)

        # Get all user profiles excluding system profiles and current user
        $excludePatterns = @(
            '*systemprofile*',
            '*Administrator*',
            '*NetworkService*',
            '*LocalService*',
            "*$env:USERNAME*"
        )

    } #end Begin

    Process {
        try {

            Write-Verbose -Message 'Retrieving user profiles...'
            $profiles = Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop |
                Where-Object {
                    $path = $_.LocalPath
                    -not $_.Loaded -and
                    -not ($excludePatterns | Where-Object { $path -like $_ })
                }

            $totalProfiles = @($profiles).Count
            Write-Verbose -Message ('Found {0} eligible profiles' -f $totalProfiles)

            if ($totalProfiles -gt 0) {
                $processed = 0

                foreach ($profile in $profiles) {
                    $processed++

                    Write-Progress -Activity 'Removing Old User Profiles' `
                        -Status ('Processing {0}' -f $profile.LocalPath) `
                        -PercentComplete (($processed / $totalProfiles) * 100)

                    try {

                        $lastUsed = $profile.ConvertToDateTime($profile.LastUseTime)
                        $profileSize = (Get-ChildItem -Path $profile.LocalPath -Recurse -Force -ErrorAction SilentlyContinue |
                                Measure-Object -Property Length -Sum).Sum

                        if ($lastUsed -lt $cutoffDate) {

                            $message = ('Remove profile: {0} (Last used: {1})' -f
                                $profile.LocalPath, $lastUsed)

                            if ($PSCmdlet.ShouldProcess($message, 'Remove Profile')) {
                                Remove-CimInstance -InputObject $profile -ErrorAction Stop
                                $result.ProfilesRemoved++
                                $result.BytesFreed += $profileSize
                                Write-Debug -Message ('Removed profile: {0}' -f $profile.LocalPath)
                            } #end If

                        } else {

                            Write-Debug -Message ('Skipping profile {0} - Last used {1}' -f
                                $profile.LocalPath, $lastUsed)

                        } #end If-Else

                    } catch {
                        # Handle orphaned profiles
                        if (-not $profile.LastUseTime) {

                            Write-Warning -Message ('Removing orphaned profile: {0}' -f $profile.LocalPath)
                            Remove-CimInstance -InputObject $profile -ErrorAction Stop
                            $result.ProfilesRemoved++

                        } else {

                            $errorMsg = ('Error processing {0}: {1}' -f
                                $profile.LocalPath, $_.Exception.Message)
                            Write-Warning -Message $errorMsg
                            $result.Errors += $errorMsg

                        } #end If-Else

                    } #end try-catch

                } #end foreach

            } #end if

            # Success should be based on whether we had errors, not whether profiles were found
            $result.Success = ($result.Errors.Count -eq 0)

        } catch {

            Write-Error -Message ('Failed to process profiles: {0}' -f $_.Exception.Message)
            $result.Errors += $_.Exception.Message

        } finally {

            Write-Progress -Activity 'Removing Old User Profiles' -Completed

        } #end try-catch-finally

    } #end Process

    End {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'clear user profiles.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $result
    } #end End
} #end function Clear-UserProfile
