Function New-gMSAScheduledTask {

    <#
        .SYNOPSIS
            Creates a scheduled task using a Group Managed Service Account (gMSA) with enhanced security.

        .DESCRIPTION
            Creates and configures scheduled tasks that run under a Group Managed Service Account (gMSA)
            with specified schedules and security settings. Supports both daily and weekly scheduling
            with multiple execution times and proper error handling.

            Key features:
            - Secure gMSA integration with proper permission validation
            - Flexible scheduling options (daily/weekly with multiple executions)
            - Enhanced security settings and task hardening
            - Comprehensive error handling and logging
            - Support for high-availability scenarios

        .PARAMETER TaskName
            The name of the scheduled task. Must be unique within the task folder.

        .PARAMETER TaskAction
            The arguments to pass to the executable. Should include all necessary parameters.

        .PARAMETER ActionPath
            Full path to the executable or PowerShell script to run. Must exist and be accessible.

        .PARAMETER gMSAAccount
            The Group Managed Service Account (gMSA) that will run the task. Must exist and be properly configured.

        .PARAMETER Description
            Optional description for the scheduled task. Default is 'Scheduled task created using gMSA.'

        .PARAMETER TriggerType
            The type of schedule trigger: 'Daily' or 'Weekly'.

        .PARAMETER StartTime
            The time to start the task in HH:mm format (24-hour).

        .PARAMETER DaysOfWeek
            Required for weekly tasks. Specifies which days to run the task.

        .PARAMETER TimesPerDay
            For daily tasks, specifies how many times per day to run. Valid values: 1,2,3,4,6,8,12,24,48.

        .OUTPUTS
            [Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask]
            Returns the created scheduled task object.

        .EXAMPLE
            $params = @{
                TaskName = "Daily-Backup"
                TaskAction = "-ExecutionPolicy Bypass -File 'C:\Scripts\Backup.ps1'"
                ActionPath = "pwsh.exe"
                gMSAAccount = "backup_gmsa$"
                TriggerType = "Daily"
                StartTime = "23:00"
                TimesPerDay = 1
            }
            New-gMSAScheduledTask @params

            Creates a daily backup task running at 23:00 using the specified gMSA.

        .EXAMPLE
            $params = @{
                TaskName = "Weekly-Maintenance"
                TaskAction = "-ExecutionPolicy Bypass -File 'C:\Scripts\Maintenance.ps1'"
                ActionPath = "pwsh.exe"
                gMSAAccount = "maint_gmsa$"
                TriggerType = "Weekly"
                StartTime = "03:00"
                DaysOfWeek = "Saturday","Sunday"
                Description = "Weekend maintenance tasks"
            }
            New-gMSAScheduledTask @params

            Creates a weekend maintenance task running at 03:00 on Saturdays and Sundays.

        .NOTES
            Used Functions:
                Name                                   ║ Module
                ═══════════════════════════════════════╬══════════════════════════════
                Get-AdObjectType                       ║ ActiveDirectory
                New-ScheduledTaskAction                ║ ScheduledTasks
                New-ScheduledTaskTrigger               ║ ScheduledTasks
                New-ScheduledTaskPrincipal             ║ ScheduledTasks
                New-ScheduledTaskSettingsSet           ║ ScheduledTasks
                Register-ScheduledTask                 ║ ScheduledTasks
                Set-ScheduledTask                      ║ ScheduledTasks
                Write-Verbose                          ║ Microsoft.PowerShell.Utility
                Write-Error                            ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
            DateModified:    08/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'Daily')]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    # [Microsoft.Management.Infrastructure.CimInstance#ROOT / Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask]

    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the name of the Scheduled Task.',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[\w\-\. ]+$')]
        [string]
        $TaskName,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the action that the task will run (arguments for the executable).',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskAction,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the full path for the executable or script (e.g., Powershell.exe or script path).',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (-not (Test-Path $_)) {
                    throw "ActionPath '$_' does not exist."
                }
                return $true
            })]
        [string]
        $ActionPath,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the gMSA account that will run the task.',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        $gMSAAccount,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Optional: Provide a description for the scheduled task.',
            Position = 4)]
        [PSDefaultValue(
            Help = 'Default Value is "Scheduled task created using gMSA."',
            Value = 'Scheduled task created using gMSA.'
        )]
        [string]
        $Description,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the type of task trigger: Daily or Weekly.',
            Position = 5)]
        [ValidateSet('Daily', 'Weekly')]
        [string]
        $TriggerType,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the time the task should run (HH:mm format).',
            Position = 6)]
        [ValidatePattern(
            '^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
            ErrorMessage = 'Time must be in HH:mm format.'
        )]
        [string]
        $StartTime,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'For weekly tasks, specify the days of the week.',
            ParameterSetName = 'WeeklyTrigger',
            Position = 7)]
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [string[]]
        $DaysOfWeek,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'For daily tasks, specify how many times per day the task should run. Acceptable values: 1, 2, 3, 4, 6, 8, 12, 24, 48.',
            ParameterSetName = 'DailyTrigger',
            Position = 8)]
        [ValidateSet(1, 2, 3, 4, 6, 8, 12, 24, 48)]
        [PSDefaultValue(
            Help = 'Default Value is "1"',
            Value = 1
        )]
        [int]
        $TimesPerDay
    )

    begin {
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


        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        #$triggerList = [System.Collections.Generic.List[object]]::New()
        $triggerList = @()

        # Validate if the gMSA account exists
        $gMSAAccount = Get-AdObjectType -Identity $PSBoundParameters['gMSAAccount']
        if ($gMSAAccount.ObjectClass -ne 'msDS-GroupManagedServiceAccount') {
            throw "Account '$gMSAAccount' is not a valid gMSA account."
        } #end If

        # Initialize collections
        $triggers = [System.Collections.Generic.List[Microsoft.Management.Infrastructure.CimInstance]]::new()

        # Create base task action
        $actionParams = @{
            Execute  = $PSBoundParameters['ActionPath']
            Argument = $PSBoundParameters['TaskAction']
        }

        # Prepare the action
        $action = New-ScheduledTaskAction @actionParams -ErrorAction Stop

        Write-Verbose -Message ('
            Scheduled task action prepared:
                Action Path: {0}
                Task Action: {1}' -f
            $PSBoundParameters['ActionPath'], $PSBoundParameters['TaskAction']
        )
    } #end begin

    process {

        if (-not $PSCmdlet.ShouldProcess($TaskName, 'Create scheduled task')) {
            return
        }

        try {
            # Process the trigger based on TriggerType
            switch ($PSBoundParameters['TriggerType']) {
                'Weekly' {
                    if (-not $PSBoundParameters['DaysOfWeek']) {
                        Write-Error -Message 'For a weekly task, you must specify at least one day of the week.'
                        return
                    } #end If

                    $triggerParams = @{
                        Weekly      = $true
                        DaysOfWeek  = $PSBoundParameters['DaysOfWeek']
                        At          = [DateTime]::ParseExact($PSBoundParameters['StartTime'], 'HH:mm', $null)
                        RandomDelay = (New-TimeSpan -Minutes 15)
                    }
                    $triggers.Add((New-ScheduledTaskTrigger @triggerParams))

                } #end Weekly

                'Daily' {
                    $intervalMinutes = [math]::Round(1440 / $PSBoundParameters['TimesPerDay'])
                    $baseTime = [DateTime]::ParseExact($PSBoundParameters['StartTime'], 'HH:mm', $null)

                    for ($i = 0; $i -lt $TimesPerDay; $i++) {

                        $triggerTime = $baseTime.AddMinutes($i * $intervalMinutes)

                        $triggerParams = @{
                            Daily       = $true
                            At          = $triggerTime
                            RandomDelay = (New-TimeSpan -Minutes 15)
                        }
                        $triggers.Add((New-ScheduledTaskTrigger @triggerParams))
                    }
                } #end Daily

            } #end switch

            # Create the task principal with gMSA account
            $Splat = @{
                UserId    = '{0}\{1}' -f $env:USERDOMAIN, $gMSAAccount.SamAccountName
                LogonType = 'Password'
                RunLevel  = 'Highest'
            }
            $principal = New-ScheduledTaskPrincipal @Splat
            Write-Verbose -Message ('Scheduled task principal created for gMSA {0}.' -f $gMSAAccount)

            # Configure task settings
            $settingsParams = @{
                AllowStartIfOnBatteries    = $true
                Compatibility              = 'Win8'
                DontStopIfGoingOnBatteries = $true
                Hidden                     = $false
                Priority                   = 6
                StartWhenAvailable         = $true
                WakeToRun                  = $false
            }
            $taskSettings = New-ScheduledTaskSettingsSet @settingsParams

            # Register the task
            $taskParams = @{
                TaskName    = $PSBoundParameters['TaskName']
                Action      = $action
                Trigger     = $triggers
                Principal   = $principal
                Settings    = $taskSettings
                Description = $PSBoundParameters['Description']
            }

            $task = Register-ScheduledTask @taskParams
            $task.Author = $env:USERNAME
            $task | Set-ScheduledTask

            Write-Verbose -Message ('
                    Scheduled task {0}
                    successfully created with gMSA {1}.' -f
                $PSBoundParameters['TaskName'], $gMSAAccount
            )

            Write-Output $task

        } catch {

            Write-Error -Message ('Failed to create the scheduled task: {0}' -f $_.Exception.Message)
            throw

        } #end try-catch

    } #end process

    end {
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'creation of scheduled task.'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end end
} #end Function


# Example Usage:
# For weekly task:
# New-ScheduledTaskWithGMSA -TaskName "WeeklyTask" -TaskAction "-File C:\Scripts\MyScript.ps1" -ActionPath "Powershell.exe" -gMSAAccount "gmsaAccount$" -TriggerType "Weekly" -StartTime "09:00" -DaysOfWeek Monday,Wednesday,Friday

# For daily task (4 times per day):
# New-ScheduledTaskWithGMSA -TaskName "DailyTask" -TaskAction "-File C:\Scripts\MyScript.ps1" -ActionPath "Powershell.exe" -gMSAAccount "gmsaAccount$" -TriggerType "Daily" -StartTime "09:00" -TimesPerDay 4
