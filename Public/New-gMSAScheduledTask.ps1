Function New-gMSAScheduledTask {

    <#
        .SYNOPSIS
            Creates a scheduled task using a Group Managed Service Account (gMSA).

        .DESCRIPTION
            This advanced function allows you to create a scheduled task that uses a gMSA to
            run specified actions. You can set the task to run either on specific days of
            the week (Weekly) or several times per day (Daily).

        .PARAMETER TaskName
            The name of the scheduled task.

        .PARAMETER TaskAction
            The arguments to pass to the executable (e.g., the script or action to run).

        .PARAMETER ActionPath
            The full path to the executable or script that will be run by the task.

        .PARAMETER gMSAAccount
            The Group Managed Service Account (gMSA) that will run the task.

        .PARAMETER Description
            A description for the scheduled task.

        .PARAMETER TriggerType
            The type of trigger to use (either "Daily" or "Weekly").

        .PARAMETER StartTime
            The time the task will start (HH:mm format).

        .PARAMETER DaysOfWeek
            Days of the week on which the task will run (for Weekly triggers).

        .PARAMETER TimesPerDay
            The number of times the task should run per day (for Daily triggers).
            Accepts values: 1, 2, 3, 4, 6, 8, 12, 24 or 48.

        .EXAMPLE
            New-ScheduledTaskWithGMSA -TaskName "MyDailyTask" -TaskAction "-File C:\Scripts\MyScript.ps1"
            -ActionPath "Powershell.exe" -gMSAAccount "gmsaTaskAccount$"
            -TriggerType "Daily" -StartTime "09:00" -TimesPerDay 4

            Creates a scheduled task that runs four times per day at intervals starting
            at 9:00 AM using the specified gMSA.

        .EXAMPLE
            New-ScheduledTaskWithGMSA -TaskName "MyWeeklyTask" -TaskAction "-File C:\Scripts\MyScript.ps1"
            -ActionPath "Powershell.exe" -gMSAAccount "gmsaTaskAccount$" -TriggerType "Weekly"
            -StartTime "08:00" -DaysOfWeek Monday,Wednesday,Friday

            Creates a scheduled task that runs every Monday, Wednesday, and Friday
            at 8:00 AM using the specified gMSA.

        .INPUTS
            None. You must provide all inputs.

        .OUTPUTS
            Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask
            The function outputs a Scheduled Task object upon successful creation.

        .NOTES
            This script requires Windows Task Scheduler cmdlets and an Active Directory
            environment where gMSA is enabled.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    # [Microsoft.Management.Infrastructure.CimInstance#ROOT / Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask]

    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the name of the Scheduled Task.',
            Position = 0)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskName,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the action that the task will run (arguments for the executable).',
            Position = 1)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskAction,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the full path for the executable or script (e.g., Powershell.exe or script path).',
            Position = 2)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ActionPath,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the gMSA account that will run the task.',
            Position = 3)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateNotNullOrEmpty()]
        $gMSAAccount,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Optional: Provide a description for the scheduled task.',
            Position = 4)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [string]
        $Description,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the type of task trigger: Daily or Weekly.',
            Position = 5)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateSet('Daily', 'Weekly')]
        [string]
        $TriggerType,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Specify the time the task should run (HH:mm format).',
            Position = 6)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateNotNullOrEmpty()]
        [string]
        $StartTime,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'For weekly tasks, specify the days of the week.',
            Position = 7)]
        [Parameter(ParameterSetName = 'WeeklyTrigger')]
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [string[]]
        $DaysOfWeek,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'For daily tasks, specify how many times per day the task should run. Acceptable values: 1, 2, 3, 4, 6, 8, 12, 24.',
            Position = 8)]
        [Parameter(ParameterSetName = 'DailyTrigger')]
        [ValidateSet(1, 2, 3, 4, 6, 8, 12, 24, 48)]
        [PSDefaultValue(Help = 'Default Value is "1"')]
        [int]
        $TimesPerDay = 1
    )

    begin {
        # Initial verbose message
        Write-Verbose -Message ('
            Starting the process to create the
                scheduled task {0}
                using gMSA {1}.' -f
            $PSBoundParameters['TaskName'], $PSBoundParameters['gMSAAccount']
        )


        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Validate if the gMSA account exists
        $gMSAAccount = Get-AdObjectType -Identity $PSBoundParameters['gMSAAccount']

        # Prepare the action
        $action = New-ScheduledTaskAction -Execute $PSBoundParameters['ActionPath'] -Argument $PSBoundParameters['TaskAction']
        Write-Verbose -Message ('
            Scheduled task action prepared:
                Action Path: {0}
                Task Action: {1}' -f
            $PSBoundParameters['ActionPath'], $PSBoundParameters['TaskAction']
        )
    } #end begin

    process {

        # Process the trigger based on TriggerType
        switch ($PSBoundParameters['TriggerType']) {
            'Weekly' {
                if (-not $PSBoundParameters['DaysOfWeek']) {
                    Write-Error -Message 'For a weekly task, you must specify at least one day of the week.'
                    return
                } #end If

                $Splat = @{
                    Weekly     = $true
                    DaysOfWeek = $PSBoundParameters['DaysOfWeek']
                    At         = $PSBoundParameters['StartTime']
                }
                $trigger = New-ScheduledTaskTrigger @Splat

                Write-Verbose -Message ('
                    Weekly trigger
                        created at {0}
                        on {1}.' -f
                    $PSBoundParameters['StartTime'], ($PSBoundParameters['DaysOfWeek'] -join ', ')
                )

            } #end Weekly

            'Daily' {
                $triggerList = @()
                $intervalMinutes = [math]::Round(1440 / $PSBoundParameters['TimesPerDay'])  # 1440 minutes in a day

                for ($i = 0; $i -lt $PSBoundParameters['TimesPerDay']; $i++) {
                    # Calculate the start time for each occurrence
                    $currentTriggerTime = (Get-Date -Hour ([int]$PSBoundParameters['StartTime'].Split(':')[0]) -Minute ([int]$PSBoundParameters['StartTime'].Split(':')[1])).AddMinutes($i * $intervalMinutes)
                    $trigger = New-ScheduledTaskTrigger -Daily -At $currentTriggerTime.ToString('HH:mm')
                    $triggerList += $trigger

                    Write-Verbose -Message ('Daily trigger created at {0}.' -f $currentTriggerTime.ToString('HH:mm'))
                } #end for
            } #end Daily

        } #end switch

        if ($PSCmdlet.ShouldProcess("Scheduled Task: $PSBoundParameters['TaskName']")) {

            try {

                # Create the task principal with gMSA account
                $Splat = @{
                    UserId    = $gMSAAccount
                    LogonType = 'Password'
                    RunLevel  = 'Highest'
                }
                $principal = New-ScheduledTaskPrincipal @Splat
                Write-Verbose -Message ('Scheduled task principal created for gMSA {0}.' -f $gMSAAccount)

                # Register the task
                $Splat = @{
                    AllowStartIfOnBatteries    = $true
                    DontStopIfGoingOnBatteries = $true
                    StartWhenAvailable         = $true
                }
                $taskSettings = New-ScheduledTaskSettingsSet @Splat

                $Splat = @{
                    TaskName    = $PSBoundParameters['TaskName']
                    Action      = $action
                    Trigger     = $triggerList
                    Principal   = $principal
                    Settings    = $taskSettings
                    Description = $PSBoundParameters['Description']
                }
                $task = Register-ScheduledTask @Splat

                Write-Verbose -Message ('
                    Scheduled task {0}
                    successfully created with gMSA {1}.' -f
                    $PSBoundParameters['TaskName'], $gMSAAccount
                )

                Write-Output $task
            } catch {
                Write-Error -Message ('Failed to create the scheduled task: {0}' -f $_)
            } #end try-catch
        } #end if
    } #end process

    end {
        Write-Verbose -Message ('Scheduled task creation process completed for {0}.' -f $PSBoundParameters['TaskName'])
    } #end end
} #end Function


# Example Usage:
# For weekly task:
# New-ScheduledTaskWithGMSA -TaskName "WeeklyTask" -TaskAction "-File C:\Scripts\MyScript.ps1" -ActionPath "Powershell.exe" -gMSAAccount "gmsaAccount$" -TriggerType "Weekly" -StartTime "09:00" -DaysOfWeek Monday,Wednesday,Friday

# For daily task (4 times per day):
# New-ScheduledTaskWithGMSA -TaskName "DailyTask" -TaskAction "-File C:\Scripts\MyScript.ps1" -ActionPath "Powershell.exe" -gMSAAccount "gmsaAccount$" -TriggerType "Daily" -StartTime "09:00" -TimesPerDay 4
