Describe 'New-gMSAScheduledTask' {
    BeforeAll {
        # Mock dependencies
        $mockGMSA = @{
            ObjectClass       = 'msDS-GroupManagedServiceAccount'
            SamAccountName    = 'testgMSA$'
            DistinguishedName = 'CN=testgMSA,CN=Managed Service Accounts,DC=EguibarIT,DC=local'
        }

        Mock Get-AdObjectType { [PSCustomObject]$mockGMSA }
        Mock Test-Path { $true }
        Mock New-ScheduledTaskAction { }
        Mock New-ScheduledTaskTrigger { }
        Mock New-ScheduledTaskPrincipal { }
        Mock New-ScheduledTaskSettingsSet { }
        Mock Register-ScheduledTask {
            [PSCustomObject]@{
                TaskName = $TaskName
                Author   = $env:USERNAME
            }
        }
        Mock Set-ScheduledTask { }
    }

    Context 'Parameter Validation' {
        It 'Should require TaskName' {
            $params = @{
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Daily'
                StartTime   = '09:00'
            }
            { New-gMSAScheduledTask @params } | Should -Throw
        }

        It 'Should validate StartTime format' {
            $params = @{
                TaskName    = 'Test'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Daily'
                StartTime   = '25:00'
            }
            { New-gMSAScheduledTask @params } | Should -Throw
        }

        It 'Should require DaysOfWeek for weekly tasks' {
            $params = @{
                TaskName    = 'Test'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Weekly'
                StartTime   = '09:00'
            }
            { New-gMSAScheduledTask @params } | Should -Throw
        }
    }

    Context 'Task Creation' {
        It 'Should create a daily task' {
            $params = @{
                TaskName    = 'DailyTest'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Daily'
                StartTime   = '09:00'
                TimesPerDay = 2
            }
            $result = New-gMSAScheduledTask @params
            $result | Should -Not -BeNullOrEmpty
            $result.TaskName | Should -Be 'DailyTest'
        }

        It 'Should create a weekly task' {
            $params = @{
                TaskName    = 'WeeklyTest'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Weekly'
                StartTime   = '09:00'
                DaysOfWeek  = @('Monday', 'Wednesday')
            }
            $result = New-gMSAScheduledTask @params
            $result | Should -Not -BeNullOrEmpty
            $result.TaskName | Should -Be 'WeeklyTest'
        }
    }

    Context 'Error Handling' {
        It 'Should handle invalid gMSA accounts' {
            Mock Get-AdObjectType {
                [PSCustomObject]@{ ObjectClass = 'user' }
            }
            $params = @{
                TaskName    = 'Test'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'invalid$'
                TriggerType = 'Daily'
                StartTime   = '09:00'
            }
            { New-gMSAScheduledTask @params } | Should -Throw
        }

        It 'Should handle task registration failures' {
            Mock Register-ScheduledTask { throw 'Registration failed' }
            $params = @{
                TaskName    = 'Test'
                TaskAction  = '-File C:\test.ps1'
                ActionPath  = 'pwsh.exe'
                gMSAAccount = 'testgMSA$'
                TriggerType = 'Daily'
                StartTime   = '09:00'
            }
            { New-gMSAScheduledTask @params } | Should -Throw
        }
    }
}
