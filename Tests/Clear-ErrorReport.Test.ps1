Describe 'Clear-ErrorReport' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock test files
        $mockFiles = @(
            [PSCustomObject]@{
                FullName = 'C:\Windows\MEMORY.DMP'
                Length   = 1024 * 1024 # 1MB
            },
            [PSCustomObject]@{
                FullName = 'C:\ProgramData\Microsoft\Windows\WER\Report.wer'
                Length   = 512 * 1024 # 512KB
            }
        )

        Mock Get-ChildItem { $mockFiles }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should support WhatIf' {
            (Get-Command Clear-ErrorReport).Parameters['WhatIf'] |
                Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function execution' {
        It 'Should process cleanup successfully' {
            $result = Clear-ErrorReport
            $result.Success | Should -Be $true
            $result.FilesRemoved | Should -Be 2
            $result.BytesFreed | Should -Be (1536 * 1024) # 1.5MB
        }

        It 'Should handle no files found' {
            Mock Get-ChildItem { $null }
            $result = Clear-ErrorReport
            $result.FilesRemoved | Should -Be 0
            $result.Success | Should -Be $false
        }

        It 'Should handle removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-ErrorReport
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'Administrative privileges' {
        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-ErrorReport } | Should -Throw 'requires administrative privileges'
        }
    }
}
