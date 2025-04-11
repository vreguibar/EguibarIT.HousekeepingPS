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

    # Mock AD cmdlets
    Mock -CommandName Get-ADDomainController -MockWith {
        [PSCustomObject]$Script:MockObjects.DomainController
    }
    Mock -CommandName Get-ADComputer -MockWith {
        @([PSCustomObject]$Script:MockObjects.Server) # Return array to support Count property
    }
    Mock -CommandName Get-ADGroup -MockWith { $null }
    Mock -CommandName New-ADGroup -MockWith {
        [PSCustomObject]$Script:MockObjects.Group
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
            Mock -CommandName Get-ADGroup -MockWith { $null }
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
        It 'Should handle domain controller connection failure' {
            Mock -CommandName Get-ADDomainController -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADServerDownException]::new('Cannot connect to DC')
            }
            { Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath } |
                Should -Throw -ExceptionType ([Microsoft.ActiveDirectory.Management.ADServerDownException])
        }

        It 'Should handle group creation failure' {
            Mock -CommandName New-ADGroup -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADException]::new('Failed to create group')
            }
            { Set-AdLocalAdminHousekeeping -LDAPPath $TestValues.LDAPPath } |
                Should -Throw -ExceptionType ([Microsoft.ActiveDirectory.Management.ADException])
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
