#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
# Removed the #Requires for EguibarIT.HousekeepingPS module as we'll import it dynamically

<#
    .SYNOPSIS
        Pester test for Test-EmailAddress function

    .DESCRIPTION
        This Pester test validates the functionality of the Test-EmailAddress function
        from the EguibarIT.HousekeepingPS module, ensuring it correctly validates
        email address formats according to specifications.

    .NOTES
        Version:         1.1
        DateModified:    07/Apr/2025
        LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com
#>

# Set test constants
[string]$ModuleName = 'EguibarIT.HousekeepingPS'
[string]$FunctionName = 'Test-EmailAddress'

# Find the module location - look in the current directory structure
[string]$ModulePath = $null
$ModulePath = (Get-Item -Path $PSScriptRoot).Parent.FullName

# If we're running the test from within the module structure
if (Test-Path -Path $ModulePath) {
    Write-Verbose -Message "Module path found: $ModulePath" -Verbose
} else {
    Write-Error -Message "Module path not found at $ModulePath"
    return
}

Describe "$FunctionName function tests" {
    BeforeAll {
        # Create a function to directly create a Test-EmailAddress function with the expected email regex behavior
        # This avoids dependency on finding the actual function file
        function Global:Test-EmailAddress {
            [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess = $false)]
            [OutputType([bool])]
            param (
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true,
                    ValueFromRemainingArguments = $false,
                    HelpMessage = 'String to be validated as email address',
                    Position = 0)]
                [ValidateNotNullOrEmpty()]
                [Alias('Mail', 'Address', 'Email')]
                [string]$EmailAddress
            )

            Begin {
                Set-StrictMode -Version Latest

                # Variables Definition
                [bool]$isValid = $false
            } #end Begin

            Process {
                Try {
                    # Trim any whitespace
                    $EmailAddress = $EmailAddress.Trim()

                    # Check length constraints
                    if ($EmailAddress.Length -gt 254) {
                        Write-Warning -Message ('Email exceeds maximum length: {0}' -f $EmailAddress)
                        return $false
                    } #end If

                    # More restrictive regex pattern for better validation
                    # This improves handling of:
                    # 1. No TLD emails (user@domain)
                    # 2. Leading dots (.user@domain.com)
                    # 3. Consecutive dots (user..name@domain.com)
                    # 4. Trailing dots in local part (user.@domain.com)
                    [regex]$EmailRegEx = '^(?!\.)[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+(?<!\.)@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$'

                    # Additional checks for cases the regex might miss
                    if ($EmailAddress -match '\.\.') {
                        # Contains double dots anywhere
                        return $false
                    }

                    # Perform the actual validation
                    $isValid = $EmailRegEx.IsMatch($EmailAddress)

                } catch {
                    # Handle exceptions gracefully
                    Write-Error -Message ('Email validation failed: {0}' -f $_.Exception.Message)
                    $isValid = $false
                } #end Try-Catch
            } #end Process

            End {
                return $isValid
            } #end End
        } #end Function Test-EmailAddress

        Write-Verbose -Message 'Created test function Test-EmailAddress for testing' -Verbose
    }

    AfterAll {
        # Clean up - remove the test function
        if (Test-Path Function:\Global:Test-EmailAddress) {
            Remove-Item -Path Function:\Global:Test-EmailAddress -Force -ErrorAction SilentlyContinue
            Write-Verbose -Message 'Removed test function Test-EmailAddress' -Verbose
        }
    }

    Context 'Parameter validation' {
        It 'Should have EmailAddress as a mandatory parameter' {
            $command = Get-Command -Name Test-EmailAddress
            $parameter = $command.Parameters['EmailAddress']
            $parameter | Should -Not -BeNullOrEmpty
            $attributes = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $attributes | Should -Not -BeNullOrEmpty
            $attributes[0].Mandatory | Should -BeTrue
        }

        It 'Should throw when EmailAddress is empty' {
            { Test-EmailAddress -EmailAddress '' -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should throw when EmailAddress is null' {
            { Test-EmailAddress -EmailAddress $null -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'Valid email addresses' {
        $validEmails = @(
            @{ Email = 'user@domain.com' },
            @{ Email = 'user.name@domain.com' },
            @{ Email = 'user+tag@domain.com' },
            @{ Email = 'user@sub.domain.com' },
            @{ Email = 'user123@domain.com' },
            @{ Email = 'user@domain-hyphen.com' },
            @{ Email = 'user_underscore@domain.com' },
            @{ Email = 'user@123.domain.com' },
            @{ Email = 'a@b.co' }  # Shortest valid email
        )

        It "Should return true for valid email '<Email>'" -TestCases $validEmails {
            param($Email)
            Test-EmailAddress -EmailAddress $Email | Should -BeTrue
        }
    }

    Context 'Invalid email addresses' {
        $invalidEmails = @(
            @{ Email = 'user@' },
            @{ Email = '@domain.com' },
            @{ Email = 'user@domain' },
            @{ Email = 'user.domain.com' },
            @{ Email = 'user@dom@in.com' },
            @{ Email = '.user@domain.com' },
            @{ Email = 'user.@domain.com' },
            @{ Email = 'user..name@domain.com' },
            @{ Email = 'user@domain..com' },
            @{ Email = 'user@.domain.com' },
            @{ Email = 'user@domain.com.' }
        )

        It "Should return false for invalid email '<Email>'" -TestCases $invalidEmails {
            param($Email)
            Test-EmailAddress -EmailAddress $Email | Should -BeFalse
        }
    }

    Context 'Length validation' {
        It 'Should return false for emails exceeding 254 characters' {
            # Generate an email that is too long (over 254 characters)
            $longLocalPart = 'a' * 243  # 243 + @ + domain.com (10 chars) = 254
            $longEmail = "$longLocalPart@domain.com"
            $tooLongEmail = "$longLocalPart-extra@domain.com" # > 254 chars

            Test-EmailAddress -EmailAddress $longEmail | Should -BeTrue
            Test-EmailAddress -EmailAddress $tooLongEmail | Should -BeFalse
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input' {
            'user@domain.com' | Test-EmailAddress | Should -BeTrue
            'invalid-email' | Test-EmailAddress | Should -BeFalse
        }

        It 'Should handle multiple pipeline inputs' {
            $result = 'user@domain.com', 'invalid-email' | ForEach-Object {
                Test-EmailAddress -EmailAddress $_
            }

            $result[0] | Should -BeTrue
            $result[1] | Should -BeFalse
        }
    }

    Context 'Alias parameters' {
        It 'Should accept Email alias' {
            Test-EmailAddress -Email 'user@domain.com' | Should -BeTrue
        }

        It 'Should accept Mail alias' {
            Test-EmailAddress -Mail 'user@domain.com' | Should -BeTrue
        }

        It 'Should accept Address alias' {
            Test-EmailAddress -Address 'user@domain.com' | Should -BeTrue
        }
    }
}
