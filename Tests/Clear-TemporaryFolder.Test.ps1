Describe 'Clear-TemporaryFolders' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock folders
        $mockFolders = @(
            @{
                Path = 'C:\Windows\Temp\test'
                Size = 1024 * 1024 # 1MB
            },
            @{
                Path = 'C:\Users\Test\AppData\Local\Temp\test'
                Size = 512 * 1024 # 512KB
            }
        )

        Mock Test-Path { $true }
        Mock Get-ChildItem {
            [PSCustomObject]@{
                Length = $mockFolders[0].Size
            }
        }
        Mock Remove-Item { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should have correct parameter attributes' {
            $command = Get-Command Clear-TemporaryFolders
            $command.Parameters['FoldersToClean'].Attributes.ValueFromPipeline |
                Should -Be $true
        }

        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-TemporaryFolders } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should process default folders' {
            $result = Clear-TemporaryFolders
            $result.Success | Should -Be $true
            $result.FoldersCleared | Should -BeGreaterThan 0
        }

        It 'Should handle custom folders' {
            $customFolders = [System.Collections.ArrayList]@('C:\CustomTemp')
            $result = Clear-TemporaryFolders -FoldersToClean $customFolders
            $result.Success | Should -Be $true
        }

        It 'Should handle removal errors' {
            Mock Remove-Item { throw 'Access denied' }
            $result = Clear-TemporaryFolders
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Success | Should -Be $false
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Clear-TemporaryFolders -WhatIf
            Should -Not -Invoke Remove-Item
        }
    }
}
