Describe 'Clear-WindowsUpdate' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock service
        $mockService = [PSCustomObject]@{
            Name          = 'wuauserv'
            Status        = 'Running'
            WaitForStatus = { param($status, $timeout) }
        }

        # Mock cache files
        $mockFiles = @(
            [PSCustomObject]@{
                FullName = 'C:\Windows\SoftwareDistribution\Download\test.dat'
                Length   = 1024 * 1024 # 1MB
            }
        )

        Mock Get-Service { $mockService }
        Mock Stop-Service { }
        Mock Start-Service { }
        Mock Test-Path { $true }
        Mock Get-ChildItem { $mockFiles }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-WindowsUpdate } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should process cache cleanup' {
            $result = Clear-WindowsUpdate
            $result.Success | Should -Be $true
            $result.BytesFreed | Should -Be (1024 * 1024)
            Should -Invoke Stop-Service -Times 1
            Should -Invoke Start-Service -Times 1
        }

        It 'Should handle service stop failure' {
            Mock Stop-Service { throw 'Service error' }
            $result = Clear-WindowsUpdate
            $result.Success | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }

        It 'Should handle cache removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-WindowsUpdate
            $result.Success | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Clear-WindowsUpdate -WhatIf
            Should -Not -Invoke Remove-Item
            Should -Not -Invoke Stop-Service
        }
    }
}
