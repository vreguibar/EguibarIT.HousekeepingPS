Describe 'Clear-DeliveryOptimizationFile' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock DeliveryOptimization status
        $mockStatus = [PSCustomObject]@{
            FileSizeInCache = 1024 * 1024 * 100 # 100MB
        }

        Mock Import-Module { }
        Mock Get-DeliveryOptimizationStatus { $mockStatus }
        Mock Delete-DeliveryOptimizationCache { }
        Mock Start-Process {
            [PSCustomObject]@{ ExitCode = 0 }
        }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-DeliveryOptimizationFile } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should clear cache using PowerShell method' {
            $result = Clear-DeliveryOptimizationFile
            $result.Success | Should -Be $true
            $result.Method | Should -Be 'PowerShell'
            $result.BytesFreed | Should -Be (1024 * 1024 * 100)
        }

        It 'Should fallback to Disk Cleanup when PowerShell fails' {
            Mock Delete-DeliveryOptimizationCache { throw 'PowerShell method failed' }
            $result = Clear-DeliveryOptimizationFile
            $result.Success | Should -Be $true
            $result.Method | Should -Be 'DiskCleanup'
        }

        It 'Should handle complete failure gracefully' {
            Mock Delete-DeliveryOptimizationCache { throw 'PowerShell failed' }
            Mock Start-Process { throw 'DiskCleanup failed' }
            $result = Clear-DeliveryOptimizationFile
            $result.Success | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Clear-DeliveryOptimizationFile -WhatIf
            Should -Not -Invoke Delete-DeliveryOptimizationCache
            Should -Not -Invoke Start-Process
        }
    }
}
