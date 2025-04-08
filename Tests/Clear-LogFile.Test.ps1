Describe 'Clear-LogFile' {
    BeforeAll {
        # Create mock files
        $mockFiles = @(
            @{
                FullName     = 'C:\Logs\old.log'
                Name         = 'old.log'
                CreationTime = (Get-Date).AddDays(-40)
                Length       = 1024 * 1024  # 1MB
            },
            @{
                FullName     = 'C:\Logs\new.log'
                Name         = 'new.log'
                CreationTime = (Get-Date).AddDays(-5)
                Length       = 512 * 1024  # 512KB
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        Mock Test-Path { $true }
        Mock Get-ChildItem { $mockFiles }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should have correct default values' {
            $command = Get-Command Clear-LogFile
            $command.Parameters['Days'].DefaultValue | Should -Be 30
            $command.Parameters['Directory'].DefaultValue |
                Should -Be 'C:\Windows\Powershell_transcriptlog'
        }

        It 'Should validate Days range' {
            { Clear-LogFile -Days 0 } | Should -Throw
            { Clear-LogFile -Days 3651 } | Should -Throw
        }
    }

    Context 'Function execution' {
        It 'Should remove old files only' {
            $result = Clear-LogFile -Directory 'C:\Logs' -Days 30
            $result.FilesRemoved | Should -Be 1
            $result.BytesFreed | Should -Be (1024 * 1024)
            $result.Success | Should -Be $true
        }

        It 'Should handle directory not found' {
            Mock Test-Path { $false }
            $result = Clear-LogFile -Directory 'C:\NonExistent'
            $result.Success | Should -Be $false
            $result.FilesRemoved | Should -Be 0
        }

        It 'Should handle removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-LogFile -Directory 'C:\Logs'
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'WhatIf support' {
        It 'Should not remove files when using WhatIf' {
            $result = Clear-LogFile -Directory 'C:\Logs' -WhatIf
            $result.FilesRemoved | Should -Be 0
            Should -Not -Invoke Remove-Item
        }
    }
}
