Describe 'Clear-AdminCount' {
    BeforeAll {
        # Mock functions
        Mock Import-MyModule { }
        Mock Get-ADObject {
            [PSCustomObject]@{
                DistinguishedName = 'CN=TestUser,DC=EguibarIT,DC=local'
                SamAccountName    = 'TestUser'
                adminCount        = 1
            }
        }
        Mock Set-ADObject { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context 'Parameter validation' {
        It 'Should have mandatory SamAccountName parameter' {
            (Get-Command Clear-AdminCount).Parameters['SamAccountName'].Attributes.Mandatory |
                Should -Be $true
        }

        It 'Should accept pipeline input' {
            (Get-Command Clear-AdminCount).Parameters['SamAccountName'].Attributes.ValueFromPipeline |
                Should -Be $true
        }
    }

    Context 'Function execution' {
        It 'Should process valid account' {
            $result = Clear-AdminCount -SamAccountName 'TestUser' -Force
            $result.Success | Should -Be $true
            Should -Invoke Set-ADObject -Times 1
        }

        It 'Should handle non-existent account' {
            Mock Get-ADObject { $null }
            $result = Clear-AdminCount -SamAccountName 'NonExistentUser' -Force
            $result.Success | Should -Be $false
            Should -Invoke Write-Warning -Times 1
        }

        It 'Should handle pipeline input' {
            $users = @('User1', 'User2')
            $results = $users | Clear-AdminCount -Force
            $results.Count | Should -Be 2
        }
    }
}
