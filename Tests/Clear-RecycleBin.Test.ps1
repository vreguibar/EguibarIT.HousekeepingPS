Describe 'Clear-RecycleBin' {
    BeforeAll {
        # Mock COM object items
        $mockItems = @(
            @{
                Name = 'test1.txt'
                Path = 'C:\$Recycle.Bin\test1.txt'
                Size = 1024 * 1024 # 1MB
            },
            @{
                Name = 'test2.txt'
                Path = 'C:\$Recycle.Bin\test2.txt'
                Size = 512 * 1024 # 512KB
            }
        ) | ForEach-Object { [PSCustomObject]$_ }

        $mockRecycler = [PSCustomObject]@{
            Items = { $mockItems }
        }

        # Mock COM object creation
        Mock New-Object { $mockRecycler } -ParameterFilter {
            $ComObject -eq 'Shell.Application'
        }

        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Function execution' {
        It 'Should process Recycle Bin items' {
            $result = Clear-RecycleBin -Confirm:$false
            $result.Success | Should -Be $true
            $result.ItemsCleared | Should -Be 2
            $result.BytesFreed | Should -Be (1536 * 1024) # 1.5MB
        }

        It 'Should handle empty Recycle Bin' {
            $mockItems = @()
            $result = Clear-RecycleBin -Confirm:$false
            $result.ItemsCleared | Should -Be 0
            $result.Success | Should -Be $true
        }

        It 'Should handle removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-RecycleBin -Confirm:$false
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'ShouldProcess support' {
        It 'Should not remove items when using WhatIf' {
            $result = Clear-RecycleBin -WhatIf
            $result.ItemsCleared | Should -Be 0
            Should -Not -Invoke Remove-Item
        }
    }
}
