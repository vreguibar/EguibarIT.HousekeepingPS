Describe 'Get-RandomPassword' {
    Context 'Parameter Validation' {
        It 'Should accept valid password length' {
            { Get-RandomPassword -PasswordLength 15 } | Should -Not -Throw
        }

        It 'Should reject password length less than 4' {
            { Get-RandomPassword -PasswordLength 3 } | Should -Throw
        }

        It 'Should reject password length greater than 256' {
            { Get-RandomPassword -PasswordLength 257 } | Should -Throw
        }

        It 'Should accept valid complexity levels' {
            1..4 | ForEach-Object {
                { Get-RandomPassword -Complexity $_ } | Should -Not -Throw
            }
        }

        It 'Should reject invalid complexity levels' {
            { Get-RandomPassword -Complexity 0 } | Should -Throw
            { Get-RandomPassword -Complexity 5 } | Should -Throw
        }
    }

    Context 'Password Generation' {
        It 'Should generate password of specified length' {
            $password = Get-RandomPassword -PasswordLength 20
            $password.Length | Should -Be 20
        }

        It 'Should include lowercase letters with complexity 1' {
            $password = Get-RandomPassword -Complexity 1
            $password | Should -Match '[a-z]'
        }

        It 'Should include upper and lowercase with complexity 2' {
            $password = Get-RandomPassword -Complexity 2
            $password | Should -Match '[a-z]'
            $password | Should -Match '[A-Z]'
        }

        It 'Should include numbers with complexity 3' {
            $password = Get-RandomPassword -Complexity 3
            $password | Should -Match '[a-z]'
            $password | Should -Match '[A-Z]'
            $password | Should -Match '[0-9]'
        }

        It 'Should include special characters with complexity 4' {
            $password = Get-RandomPassword -Complexity 4
            $password | Should -Match '[a-z]'
            $password | Should -Match '[A-Z]'
            $password | Should -Match '[0-9]'
            $password | Should -Match '[\W_]'
        }

        It 'Should not contain ambiguous characters' {
            $password = Get-RandomPassword
            $password | Should -Not -Match '[OIl]'
        }

        It 'Should generate unique passwords' {
            $passwords = 1..10 | ForEach-Object { Get-RandomPassword }
            $uniquePasswords = $passwords | Select-Object -Unique
            $uniquePasswords.Count | Should -Be 10
        }
    }

    Context 'Performance' {
        It 'Should generate passwords quickly' {
            $time = Measure-Command {
                1..100 | ForEach-Object { Get-RandomPassword }
            }
            $time.TotalSeconds | Should -BeLessThan 1
        }
    }
}
