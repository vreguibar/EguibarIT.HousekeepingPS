BeforeAll {
    # Module Path Setup
    $ModulePath = Split-Path -Parent -Path (Split-Path -Parent -Path $PSCommandPath)
    $FunctionPath = Join-Path -Path $ModulePath -ChildPath 'Public\Set-AdLocalAdminHousekeeping.ps1'

    # Define required variables
    $Global:Variables = @{
        HeaderHousekeeping = 'Function: {0} - {1} - Parameters: {2}'
        FooterHousekeeping = 'Function: {0} - {1}'
    }

    # Mock required module functions
    function Test-IsValidDN {
        param($ObjectDN) return $true
    }
    function Get-FunctionDisplay {
        param($HashTable) return 'Parameter Display'
    }
    function Initialize-ModuleVariable {
        param($Path) return $Global:Variables
    }
    function Import-MyModule {
        return $true
    }

    # Test values
    $Script:TestValues = @{
        Domain     = 'contoso.com'
        LDAPPath   = 'OU=AdminGroups,DC=contoso,DC=com'
        ServerName = 'SERVER01'
        GroupName  = 'Admin_SERVER01'
    }

    # Mock objects
    $Script:MockObjects = @{
        DomainController = @{
            HostName = 'DC01.contoso.com'
            Domain   = $TestValues.Domain
        }
        Server           = @{
            Name              = $TestValues.ServerName
            DistinguishedName = "CN=$($TestValues.ServerName),OU=Servers,DC=contoso,DC=com"
        }
        Group            = @{
            Name          = $TestValues.GroupName
            GroupScope    = 'Global'
            GroupCategory = 'Security'
            Description   = "Local Admin group for $($TestValues.ServerName)"
        }
    }

    # Mock AD cmdlets - Ensure they return arrays to support .Count property
    Mock -CommandName Get-ADDomainController -MockWith {
        return [PSCustomObject]$Script:MockObjects.DomainController
    }

    # Always return an array for proper Count support
    Mock -CommandName Get-ADComputer -MockWith {
        return @([PSCustomObject]$Script:MockObjects.Server)
    }

    # Return empty array instead of null for Get-ADGroup
    Mock -CommandName Get-ADGroup -MockWith {
        return @()
    }

    Mock -CommandName New-ADGroup -MockWith {
        return [PSCustomObject]$Script:MockObjects.Group
    }

    Mock -CommandName Remove-ADGroup -MockWith { }

    # Mock Write cmdlets
    Mock -CommandName Write-Verbose -MockWith { }
    Mock -CommandName Write-Progress -MockWith { }
    Mock -CommandName Write-Error -MockWith { }
    Mock -CommandName Write-Warning -MockWith { }
    Mock -CommandName Test-IsValidDN -MockWith { $true }
    Mock -CommandName Import-Module -MockWith { }

    # Load function directly
    . $FunctionPath
}

Describe 'Set-AdLocalAdminHousekeeping' {
    Context 'Parameter Validation' {
        BeforeAll {
            $CommandInfo = Get-Command -Name Set-AdLocalAdminHousekeeping -ErrorAction Stop
            $CmdletBindingAttribute = $CommandInfo.ScriptBlock.Attributes |
                Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
        }

        It 'Should have SupportsShouldProcess enabled' {
            $CmdletBindingAttribute.SupportsShouldProcess | Should -BeTrue
        }

        It 'Should accept pipeline input for Domain parameter' {
            $CommandInfo.Parameters['Domain'].Attributes.Where{
                $_ -is [System.Management.Automation.ParameterAttribute]
            }.ValueFromPipeline | Should -BeTrue
        }

        It 'Should require LDAPPath parameter' {
            $CommandInfo.Parameters['LDAPPath'].Attributes.Where{
                $_ -is [System.Management.Automation.ParameterAttribute]
            }.Mandatory | Should -BeTrue
        }

        It 'Should validate LDAPPath is a valid DN' {
            Mock -CommandName Test-IsValidDN -MockWith { $false }
            { Set-AdLocalAdminHousekeeping -LDAPPath 'Invalid DN' } |
                Should -Throw
        }
    }

    Context 'Function Behavior' {
        BeforeEach {
            # Ensure we're returning an empty array, not null
            Mock -CommandName Get-ADGroup -MockWith { return @() }
        }

        It 'Should discover domain controller' {
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -WhatIf
            Should -Invoke -CommandName Get-ADDomainController -Times 1 -Exactly
        }

        It 'Should get server list' {
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -WhatIf
            Should -Invoke -CommandName Get-ADComputer -Times 1 -Exactly
        }

        It 'Should create missing admin group' {
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -Confirm:$false
            Should -Invoke -CommandName New-ADGroup -Times 1 -Exactly -ParameterFilter {
                $Name -eq $TestValues.GroupName -and
                $Path -eq $TestValues.LDAPPath
            }
        }
    }

    Context 'Error Handling' {
        BeforeEach {
            # Mock Write cmdlets to capture error messages
            Mock -CommandName Write-Error -MockWith { }
            Mock -CommandName Write-Warning -MockWith { }

            # Create collections that properly support Count property
            # Always use arrays for consistency
            $EmptyResult = @()
            $SingleGroup = @(
                [PSCustomObject]@{
                    Name              = 'Admin_NONEXISTENT'
                    DistinguishedName = "CN=Admin_NONEXISTENT,$($TestValues.LDAPPath)"
                    ObjectClass       = 'group'
                }
            )

            # Ensure these mocks always return arrays
            Mock -CommandName Get-ADComputer -MockWith { return $EmptyResult }
            Mock -CommandName Get-ADGroup -MockWith { return $EmptyResult }
        }

        It 'Should handle domain controller connection failure' {
            # Arrange
            Mock -CommandName Get-ADDomainController -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADServerDownException]::new(
                    'Cannot connect to domain controller'
                )
            }

            # Act & Assert
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -ErrorAction SilentlyContinue
            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Message -like '*Cannot connect to domain controller*'
            }
        }

        It 'Should handle non-existent server cleanup' {
            # Arrange
            Mock -CommandName Get-ADComputer -MockWith {
                # Return empty array for no servers
                return [System.Collections.ArrayList]@()
            }

            Mock -CommandName Get-ADGroup -MockWith {
                # Return array with one obsolete group
                return [System.Collections.ArrayList]@(
                    [PSCustomObject]@{
                        Name              = 'Admin_NONEXISTENT'
                        DistinguishedName = "CN=Admin_NONEXISTENT,$($TestValues.LDAPPath)"
                        ObjectClass       = 'group'
                        SamAccountName    = 'Admin_NONEXISTENT'
                    }
                )
            }

            # Mock Remove-ADGroup to capture calls
            Mock -CommandName Remove-ADGroup -MockWith {
                return $null
            } -Verifiable

            # Mock domain controller to ensure it returns
            Mock -CommandName Get-ADDomainController -MockWith {
                return [PSCustomObject]@{
                    HostName = 'DC01.contoso.com'
                    Domain   = $TestValues.Domain
                }
            }

            # Act
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -Confirm:$false

            # Assert
            Should -Invoke -CommandName Remove-ADGroup -Times 1 -Exactly -ParameterFilter {
                $Identity.Name -eq 'Admin_NONEXISTENT'
            }
            Should -InvokeVerifiable
        }

        It 'Should handle multiple server groups' {
            # Arrange
            Mock -CommandName Get-ADComputer -MockWith {
                return @(
                    [PSCustomObject]@{
                        Name              = 'SERVER01'
                        DistinguishedName = 'CN=SERVER01,OU=Servers,DC=contoso,DC=com'
                        ObjectClass       = 'computer'
                    },
                    [PSCustomObject]@{
                        Name              = 'SERVER02'
                        DistinguishedName = 'CN=SERVER02,OU=Servers,DC=contoso,DC=com'
                        ObjectClass       = 'computer'
                    }
                )
            }

            # Act & Assert
            Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath -Confirm:$false
            Should -Invoke -CommandName New-ADGroup -Times 2 -Exactly
        }
    }
}

AfterAll {
    # Cleanup
    Remove-Variable -Name Variables -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name TestValues -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name MockObjects -Scope Script -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\Set-AdLocalAdminHousekeeping -ErrorAction SilentlyContinue
}
