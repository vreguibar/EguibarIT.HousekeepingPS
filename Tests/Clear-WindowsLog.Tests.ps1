Describe 'Clear-WindowsLog' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock service
        $mockService = [PSCustomObject]@{
            Name          = 'TrustedInstaller'
            Status        = 'Running'
            WaitForStatus = { param($status, $timeout) }
        }

        # Mock files
        $mockFiles = @(
            @{
                FullName = 'C:\Windows\Logs\test.log'
                Name     = 'test.log'
                Length   = 1024 * 1024 # 1MB
            },
            @{
                FullName = 'C:\Windows\Logs\other.log'
                Name     = 'other.log'
                Length   = 512 * 1024 # 512KB
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        Mock Get-Service { $mockService }
        Mock Stop-Process { }
        Mock Start-Service { }
        Mock Get-Process { [PSCustomObject]@{ Name = 'TrustedInstaller' } }
        Mock Test-Path { $true }
        Mock Get-ChildItem { $mockFiles }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-WindowsLog } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should process log files' {
            $result = Clear-WindowsLog
            $result.Success | Should -Be $true
            $result.LogsCleared | Should -Be 2
            $result.BytesFreed | Should -Be (1536 * 1024) # 1.5MB
        }

        It 'Should handle service errors' {
            Mock Start-Service { throw 'Service error' }
            $result = Clear-WindowsLog
            $result.Errors.Count | Should -BeGreaterThan 0
        }

        It 'Should handle file removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-WindowsLog
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Clear-WindowsLog -WhatIf
            $result.LogsCleared | Should -Be 0
            Should -Not -Invoke Remove-Item
        }
    }
}
