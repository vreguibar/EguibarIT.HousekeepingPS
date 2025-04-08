Describe 'Clear-UserProfile' {
    BeforeAll {
        # Mock administrative check
        Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $true }

        # Mock profiles
        $mockProfiles = @(
            @{
                LocalPath   = 'C:\Users\OldUser'
                LastUseTime = '20230101000000.000000+000'
                Loaded      = $false
                SID         = 'S-1-5-21-123456789-0123456789-012345678-1001'
            },
            @{
                LocalPath   = 'C:\Users\RecentUser'
                LastUseTime = (Get-Date).ToString('yyyyMMddHHmmss.000000+000')
                Loaded      = $false
                SID         = 'S-1-5-21-123456789-0123456789-012345678-1002'
            }
        ) | ForEach-Object {
            $obj = [PSCustomObject]$_
            $obj | Add-Member -MemberType ScriptMethod -Name ConvertToDateTime -Value {
                param($time)
                [DateTime]::ParseExact($time, 'yyyyMMddHHmmss.000000+000', $null)
            }
            $obj
        }

        Mock Get-CimInstance { $mockProfiles }
        Mock Remove-CimInstance { }
        Mock Write-Warning { }
        Mock Write-Error { }
        Mock Get-ChildItem {
            [PSCustomObject]@{
                Length = 1024 * 1024 # 1MB
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have correct default ProfileAge' {
            $command = Get-Command Clear-UserProfile
            $command.Parameters['ProfileAge'].DefaultValue | Should -Be 90
        }

        It 'Should require administrative rights' {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { $false }
            { Clear-UserProfile } | Should -Throw 'requires administrative privileges'
        }
    }

    Context 'Function execution' {
        It 'Should remove old profiles' {
            $result = Clear-UserProfile -ProfileAge 30
            $result.Success | Should -Be $true
            $result.ProfilesRemoved | Should -Be 1
            Should -Invoke Remove-CimInstance -Times 1
        }

        It 'Should handle orphaned profiles' {
            $mockProfiles[0].LastUseTime = $null
            $result = Clear-UserProfile
            $result.ProfilesRemoved | Should -Be 1
            Should -Invoke Write-Warning -Times 1
        }
    }

    Context 'ShouldProcess support' {
        It 'Should support WhatIf' {
            $result = Clear-UserProfile -WhatIf
            $result.ProfilesRemoved | Should -Be 0
            Should -Not -Invoke Remove-CimInstance
        }
    }
}
