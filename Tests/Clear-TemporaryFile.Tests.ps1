Describe 'Clear-TemporaryFile' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock test files
        $mockFiles = @(
            @{
                FullName = 'C:\Windows\Temp\test.tmp'
                Name     = 'test.tmp'
                Length   = 1024 * 1024 # 1MB
            },
            @{
                FullName = 'C:\Users\Test\AppData\Local\Temp\log.log'
                Name     = 'log.log'
                Length   = 512 * 1024 # 512KB
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        Mock Test-Path { $true }
        Mock Get-ChildItem { $mockFiles }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should support WhatIf' {
            (Get-Command Clear-TemporaryFile).Parameters['WhatIf'] |
                Should -Not -BeNullOrEmpty
        }

        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-TemporaryFile } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should process cleanup successfully' {
            $result = Clear-TemporaryFile -Force
            $result.Success | Should -Be $true
            $result.FilesRemoved | Should -Be 2
            $result.BytesFreed | Should -Be (1536 * 1024) # 1.5MB
        }

        It 'Should handle no matching files' {
            Mock Get-ChildItem { $null }
            $result = Clear-TemporaryFile -Force
            $result.FilesRemoved | Should -Be 0
            $result.Success | Should -Be $false
        }

        It 'Should handle removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-TemporaryFile -Force
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }
}
