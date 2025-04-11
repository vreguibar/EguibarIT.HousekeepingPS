BeforeAll {
    # Mock Variables hashtable
    $global:Variables = @{
        HeaderHousekeeping = '{0} - {1} {2}'
        FooterHousekeeping = '{0} - {1}'
    }

    # Create mock for Import-MyModule function
    function Import-MyModule {
        param([string]$Name)
    }

    # Create mock for Get-FunctionDisplay
    function Get-FunctionDisplay {
        param([hashtable]$Hashtable)
        return 'Function Display'
    }

    # Import function
    . $PSScriptRoot/../Public/Clear-AdAdminCount.ps1

    # Mock dependencies
    Mock Import-MyModule { }
    Mock Write-Progress { }
    Mock Write-Verbose { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Get-FunctionDisplay { return 'Test Display' }
    Mock Set-ADObject { }

    # Mock AD cmdlets
    $mockADObject = @{
        DistinguishedName    = 'CN=TestUser,DC=contoso,DC=com'
        adminCount           = 1
        ObjectClass          = 'user'
        nTSecurityDescriptor = New-Object System.DirectoryServices.ActiveDirectorySecurity
    }
}

Describe 'Clear-AdminCount' {
    BeforeAll {
        # Reset mocks before each test
        Mock Get-ADObject { $mockADObject }
        Mock Set-ADObject { }
        $Global:results = @()
    }

    Context 'Parameter validation' {
        It 'Should have mandatory SamAccountName parameter' {
            $command = Get-Command Clear-AdminCount
            $command.Parameters['SamAccountName'].Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory |
                Should -Be $true
        }

        It 'Should accept pipeline input for SamAccountName' {
            $command = Get-Command Clear-AdminCount
            $command.Parameters['SamAccountName'].Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.ValueFromPipeline |
                Should -Be $true
        }

        It 'Should have non-mandatory Force switch' {
            $command = Get-Command Clear-AdminCount
            $command.Parameters['Force'].Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory |
                Should -Be $false
        }
    }

    Context 'Function behavior' {
        BeforeEach {
            # Reset mocks and clear results
            Mock Get-ADObject {
                param($Filter)
                @{
                    DistinguishedName    = 'CN=TestUser,DC=contoso,DC=com'
                    adminCount           = 1
                    ObjectClass          = 'user'
                    nTSecurityDescriptor = [System.DirectoryServices.ActiveDirectorySecurity]::new()
                    SamAccountName       = $Filter.ToString() -replace '.+=\s*''?([^'']*)''?.*', '$1'
                }
            }
            Mock Set-ADObject { $true }
            Mock Write-Progress { }
            Mock Import-MyModule { }

            # Mock ADSI behavior
            $Script:mockDirectoryEntry = @{
                ObjectSecurity = @{
                    AreAccessRulesProtected = $true
                    SetAccessRuleProtection = { param($false, $true) }
                }
                CommitChanges  = { }
            }
            Mock New-Object -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' } -MockWith { $Script:mockDirectoryEntry }

            # Reset global variables that might affect the test
            $Global:results = $null
            Remove-Variable -Name results -Scope Script -ErrorAction SilentlyContinue
        }

        It 'Should process single account' {
            # Execute function
            $result = Clear-AdminCount -SamAccountName 'TestUser' -Force

            # Verify results
            $result.Count | Should -Be 1
            $result[0].SamAccountName | Should -Be 'TestUser'
            $result[0].Success | Should -Be $true
            $result[0].Message | Should -BeLike '*successfully*'
            Should -Invoke Get-ADObject -Times 1 -Exactly
            Should -Invoke Set-ADObject -Times 1 -Exactly
        }

        It 'Should process multiple accounts' {
            # Mock for multiple accounts
            Mock Get-ADObject {
                param($Filter)
                $accountName = if ($Filter.ToString() -match '(.+)$') {
                    $matches[1]
                }
                @{
                    DistinguishedName    = "CN=$accountName,DC=contoso,DC=com"
                    adminCount           = 1
                    ObjectClass          = 'user'
                    nTSecurityDescriptor = [System.DirectoryServices.ActiveDirectorySecurity]::new()
                    SamAccountName       = $accountName
                }
            }

            # Execute function
            $accounts = @('User1', 'User2')
            $results = Clear-AdminCount -SamAccountName $accounts -Force

            # Verify results
            $results.Count | Should -Be 2
            $results[0].SamAccountName | Should -Be 'User1'
            $results[1].SamAccountName | Should -Be 'User2'
            Should -Invoke Get-ADObject -Times 2 -Exactly
            Should -Invoke Set-ADObject -Times 2 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should handle non-existent account' {
            Mock Get-ADObject { $null }
            $result = Clear-AdminCount -SamAccountName 'NonExistentUser' -Force
            $result[0].Success | Should -Be $false
            $result[0].Message | Should -BeLike '*not found*'
        }

        It 'Should handle AD errors' {
            Mock Get-ADObject { throw 'AD Error' }
            $result = Clear-AdminCount -SamAccountName 'TestUser' -Force
            $result[0].Success | Should -Be $false
            $result[0].Message | Should -BeLike 'Error:*'
        }
    }

    Context 'Progress reporting' {
        It 'Should show progress for multiple items' {
            Mock Write-Progress { }
            Clear-AdminCount -SamAccountName @('User1', 'User2') -Force
            Should -Invoke Write-Progress -Times 3
        }
    }
}
