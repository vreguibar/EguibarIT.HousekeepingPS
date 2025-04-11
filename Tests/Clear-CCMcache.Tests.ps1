Describe 'Clear-CCMcache' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock CimInstance
        Mock Get-CimInstance {
            [PSCustomObject]@{
                ClientVersion = '5.00.9040.1000'
            }
        }

        # Mock COM object
        $mockCache = [PSCustomObject]@{
            GetCacheElements   = {
                @(
                    [PSCustomObject]@{
                        ContentID      = 'PKG00001'
                        Location       = 'C:\Windows\ccmcache\1'
                        CacheElementID = '12345'
                    }
                )
            }
            DeleteCacheElement = { param($id) }
        }

        Mock New-Object { $mockCache } -ParameterFilter {
            $ComObject -eq 'UIResource.UIResourceMgr'
        }

        Mock Test-Path { $true }
        Mock Get-ChildItem {
            [PSCustomObject]@{
                Length = 1024 * 1024 # 1MB
            }
        }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should have Force parameter' {
            (Get-Command Clear-CCMcache).Parameters['Force'].SwitchParameter |
                Should -Be $true
        }
    }

    Context 'When running with administrative privileges' {
        It 'Should process cache cleanup successfully' {
            $result = Clear-CCMcache -Force
            $result.Success | Should -Be $true
            $result.ItemsCleared | Should -Be 1
            $result.CacheSize | Should -Be (1024 * 1024)
        }

        It 'Should handle no cache elements gracefully' {
            Mock New-Object {
                [PSCustomObject]@{
                    GetCacheElements = { @() }
                }
            }
            $result = Clear-CCMcache -Force
            $result.Success | Should -Be $true
            $result.ItemsCleared | Should -Be 0
        }
    }

    Context 'Error handling' {
        It 'Should handle missing CCM client' {
            Mock Get-CimInstance { throw 'Not found' }
            $result = Clear-CCMcache -Force
            $result.Success | Should -Be $false
            $result.Message | Should -Match 'CCM cache folder exists'
        }

        It 'Should handle COM object failures' {
            Mock New-Object { throw 'COM error' }
            $result = Clear-CCMcache -Force
            $result.Success | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }
    }
}
