function Clear-AdminCount {
    <#
        .SYNOPSIS
            Clears the 'adminCount' attribute of an Active Directory object and resets object security inheritance.

        .DESCRIPTION
            This function retrieves an AD object by its SamAccountName, clears the 'adminCount' attribute,
            and ensures that security inheritance is reset. It can handle users, groups, and potentially other object types
            that can have security permissions.

            The adminCount attribute is used by the SDProp process to determine if an object's permissions should be
            protected. Clearing this attribute and resetting inheritance helps maintain proper security delegation.

        .PARAMETER SamAccountName
            The SamAccountName of the AD object to modify. This parameter accepts pipeline input and is mandatory.

        .PARAMETER Force
            If specified, suppresses confirmation prompts. Use with caution.

        .EXAMPLE
            Clear-AdminCount -SamAccountName 'jdoe'

            Clears the adminCount attribute and resets inheritance for user 'jdoe'

        .EXAMPLE
            'user1','user2' | Clear-AdminCount -Verbose

            Processes multiple users via pipeline with verbose output

        .EXAMPLE
            Get-ADUser -Filter {adminCount -eq 1} | Clear-AdminCount -WhatIf

            Shows what would happen when clearing adminCount for all users with adminCount=1

        .OUTPUTS
            [PSCustomObject] containing:
                SamAccountName     : The processed account name
                DistinguishedName : The object's DN
                Success          : Boolean indicating operation success
                Message          : Operation details or error message

        .NOTES
            Used Functions:
                Name                                       ║ Module/Namespace
                ═══════════════════════════════════════════╬══════════════════════════════
                Get-ADObject                               ║ ActiveDirectory
                Set-ADObject                               ║ ActiveDirectory
                Import-Module                              ║ Microsoft.PowerShell.Core
                Write-Verbose                              ║ Microsoft.PowerShell.Utility
                Write-Error                                ║ Microsoft.PowerShell.Utility
                Write-Warning                              ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay                        ║ EguibarIT.HousekeepingPS
                Import-MyModule                            ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
            DateModified:    7/Apr/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS
            https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Default'
    )]
    [OutputType([PSCustomObject[]], [System.Object[]])]

    Param(

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'The SamAccountName of the AD object to modify.',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('IdentityReference', 'Identity', 'Account')]
        [string[]]
        $SamAccountName,

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Force

    )

    Begin {

        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If


        ##############################
        # Module Import

        Import-MyModule ActiveDirectory -Verbose:$false

        ##############################
        # Variables Definition

        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Initialize counter for Write-Progress
        [int]$i = 0
        [int]$total = 1 # Will be updated when pipeline input is counted

        # Initialize results collection
        $Script:results = [System.Collections.ArrayList]::new()

    } #end Begin

    Process {
        # Update total count for progress bar if using pipeline
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $total = $SamAccountName.Count
        } #end if

        foreach ($account in $SamAccountName) {
            $i++

            # Progress bar
            $percentComplete = [Math]::Min(($i / $total) * 100, 100)
            Write-Progress -Activity 'Clearing AdminCount' -Status ('Processing {0}' -f $account) -PercentComplete $percentComplete

            Write-Debug -Message ('Processing account: {0}' -f $account)

            $result = [PSCustomObject]@{
                SamAccountName    = $account
                DistinguishedName = $null
                Success           = $false
                Message           = ''
            }

            try {
                # Get AD object with required properties
                $splat = @{
                    Filter      = { SamAccountName -eq $account }
                    Properties  = 'adminCount', 'nTSecurityDescriptor'
                    ErrorAction = 'Stop'
                } #end splat
                $adObject = Get-ADObject @Splat

                if (-not $adObject) {
                    $result.Message = ('AD object not found: {0}' -f $account)
                    Write-Warning -Message $result.Message
                    [void]$Script:results.Add($result)
                    continue
                } #end if

                $result.DistinguishedName = $adObject.DistinguishedName

                # Check if adminCount needs to be cleared
                if ($null -eq $adObject.adminCount) {

                    $result.Success = $true
                    $result.Message = 'AdminCount already null - no action needed'
                    [void]$Script:results.Add($result)
                    continue

                } #end if

                # Process if confirmed
                $message = ('Clear adminCount and reset inheritance for {0}' -f $adObject.DistinguishedName)
                if ($Force -or
                    $PSCmdlet.ShouldProcess($message)) {

                    try {
                        # Clear adminCount attribute
                        Set-ADObject -Identity $adObject.DistinguishedName -Clear adminCount -ErrorAction Stop
                        Write-Verbose -Message ('Cleared adminCount for {0}' -f $adObject.DistinguishedName)

                        # Reset inheritance using ADSI
                        $directoryEntry = [ADSI]('LDAP://{0}' -f $adObject.DistinguishedName)
                        $acl = $directoryEntry.ObjectSecurity

                        if ($acl.AreAccessRulesProtected) {
                            $acl.SetAccessRuleProtection($false, $true)
                            $directoryEntry.CommitChanges()
                            Write-Verbose -Message ('Reset inheritance for {0}' -f $adObject.DistinguishedName)
                        } #end if

                        # Set success after all operations complete
                        $result.Success = $true
                        $result.Message = 'AdminCount cleared and inheritance reset successfully'

                    } catch {

                        $result.Success = $false
                        $result.Message = ('Error while processing: {0}' -f $_.Exception.Message)
                        Write-Error -Message $result.Message

                    } #end try-catch

                    [void]$Script:results.Add($result)

                }  #end if-else

            } catch {

                $result.Message = ('Error: {0}' -f $_.Exception.Message)
                [void]$Script:results.Add($result)
                Write-Error -Message $result.Message

            } #end try-catch

        } #end foreach
        Write-Progress -Activity 'Clearing AdminCount' -Completed
    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'processing AdminCount & Permissions.'
            )
            Write-Verbose -Message $txt
        } #end If

        # Return results as array
        return @($Script:results)
    } #end End
} #end Function Clear-AdminCount
