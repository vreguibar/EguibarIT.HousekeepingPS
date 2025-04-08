Describe 'Start-DiskCleanup' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock drive info
        Mock Get-PSDrive {
            [PSCustomObject]@{
                Free = 1024 * 1024 * 1024 * 100 # 100GB
            }
        }

        # Mock cleanup functions
        Mock Clear-RecycleBin {
            [PSCustomObject]@{ Success = $true; Errors = @() }
        }
        Mock Clear-TemporaryFile {
            [PSCustomObject]@{ Success = $true; Errors = @() }
        }
        Mock Clear-WindowsLog {
            [PSCustomObject]@{ Success = $true; Errors = @() }
        }
        Mock Start-Process {
            [PSCustomObject]@{ ExitCode = 0 }
        }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Start-DiskCleanup } | Should -Throw 'requires administrative privileges'
        }

        It 'Should handle IncludeAll parameter' {
            $result = Start-DiskCleanup -IncludeAll
            $result.OperationsRun | Should -BeGreaterThan 0
        }
    }

    Context 'Function execution' {
        It 'Should run selected operations' {
            $result = Start-DiskCleanup -RecycleBin -TempFiles
            $result.Success | Should -Be $true
            $result.OperationsRun | Should -Be 2
        }

        It 'Should handle operation failures' {
            Mock Clear-RecycleBin { throw 'Operation failed' }
            $result = Start-DiskCleanup -RecycleBin
            $result.Success | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }

        It 'Should calculate space recovered' {
            Mock Get-PSDrive -ParameterFilter { $true } -MockWith {
                [PSCustomObject]@{ Free = 1024 * 1024 * 1024 * 110 } # 110GB
            }
            $result = Start-DiskCleanup -RecycleBin
            $result.SpaceRecovered | Should -BeGreaterThan 0
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Start-DiskCleanup -RecycleBin -WhatIf
            Should -Not -Invoke Clear-RecycleBin
            $result.OperationsRun | Should -Be 0
        }
    }
}
