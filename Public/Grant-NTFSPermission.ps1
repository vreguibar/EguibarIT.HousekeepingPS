function Grant-NTFSPermission {

    <#
        .SYNOPSIS
            Grants NTFS permissions to a folder or file.

        .DESCRIPTION
            The Grant-NTFSPermission function adds NTFS permissions to a specified path for a given security principal.
            It supports multiple FileSystemRights values and proper inheritance settings.

        .PARAMETER Path
            Absolute path to the file system object (folder or file).

        .PARAMETER Identity
            Name of the security principal (user, group, or computer) receiving the permission.

        .PARAMETER Permission
            FileSystemRights permission(s) to grant. Can be a single permission or multiple permissions separated by commas.
            Valid values include: ReadAndExecute, AppendData, CreateFiles, Read, Write, Modify, FullControl, ChangePermissions, TakeOwnership, etc.

        .PARAMETER InheritanceFlags
            Specifies how permissions are inherited by child objects.

        .PARAMETER PropagationFlags
            Specifies how permission inheritance is propagated to child objects.

        .PARAMETER AccessControlType
            Specifies whether the permission is Allow or Deny.

        .EXAMPLE
            Grant-NTFSPermission -Path 'C:\Shares' -Identity 'TheGood' -Permission 'FullControl'

            Grants FullControl permission to 'TheGood' on the C:\Shares folder.

        .EXAMPLE
            Grant-NTFSPermission -Path 'C:\Shares' -Identity 'TheGood' -Permission 'FullControl, ChangePermissions'

            Grants FullControl and ChangePermissions to 'TheGood' on the C:\Shares folder.

        .INPUTS
            [String]
            You can pipe the Path parameter to this function.

        .OUTPUTS
            [System.Boolean]
            Returns True if successful, otherwise False.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Get-Acl                          ║ Microsoft.PowerShell.Security
                Set-Acl                          ║ Microsoft.PowerShell.Security
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Error                      ║ Microsoft.PowerShell.Utility
                Get-Date                         ║ Microsoft.PowerShell.Utility
                Test-Path                        ║ Microsoft.PowerShell.Management
                Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.2
            DateModified:    09/Jun/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/Public/Grant-NTFSPermission.ps1

        .COMPONENT
            File System Security

        .ROLE
            Administrator

        .FUNCTIONALITY
            Manages NTFS permissions on file system objects.
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([System.Boolean])]

    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Absolute path to the file system object'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Any)) {
                    throw ('Path not found: {0}' -f $_)
                }
                return $true
            })]
        [Alias('FilePath', 'FolderPath')]
        [String]
        $Path,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'Name of the security principal receiving the permission'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Object', 'Principal', 'SecurityPrincipal')]
        [String]
        $Identity,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2,
            HelpMessage = 'FileSystemRights permission(s) to grant'
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Permission,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Inheritance flags for the permission'
        )]
        [PSDefaultValue(
            Help = 'Default value is "ContainerInherit, ObjectInherit"',
            Value = 'ContainerInherit, ObjectInherit'
        )]
        [System.Security.AccessControl.InheritanceFlags]
        $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit',

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Propagation flags for the permission'
        )]
        [PSDefaultValue(
            Help = 'Default value is "None"',
            Value = 'None'
        )]
        [System.Security.AccessControl.PropagationFlags]
        $PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Access control type (Allow or Deny)'
        )]
        [PSDefaultValue(
            Help = 'Default value is "Allow"',
            Value = 'Allow'
        )]
        [System.Security.AccessControl.AccessControlType]
        $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.HeaderHousekeeping) {

            $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports

        ##############################
        # Variables Definition

        [boolean]$Result = $false

        # Parse the permission string to handle multiple values
        $FileSystemRights = try {

            [System.Security.AccessControl.FileSystemRights]$Permission

        } catch {

            Write-Error -Message ('Invalid permission specified: {0}. Error: {1}' -f $Permission, $_.Exception.Message)
            return $false

        } #end try-catch

    } #end Begin

    Process {

        try {

            Write-Verbose -Message ('Processing NTFS permission for {0} on {1}' -f $Identity, $Path)

            if ($PSCmdlet.ShouldProcess($Path, ('Grant {0} permissions to {1}' -f $Permission, $Identity))) {

                # Create the NT Account object
                $Account = try {

                    [System.Security.Principal.NTAccount]::new($Identity)

                } catch {

                    Write-Error -Message ('Failed to create NT Account for {0}: {1}' -f $Identity, $_.Exception.Message)
                    return $false

                } #end try-catch

                # Create the FileSystemAccessRule
                $FileSystemAccessRule = try {

                    [System.Security.AccessControl.FileSystemAccessRule]::new(
                        $Account,
                        $FileSystemRights,
                        $InheritanceFlags,
                        $PropagationFlags,
                        $AccessControlType
                    )

                } catch {

                    Write-Error -Message ('Failed to create FileSystemAccessRule: {0}' -f $_.Exception.Message)
                    return $false

                } #end try-catch

                # Get current ACL
                $DirectorySecurity = try {

                    Get-Acl -Path $Path -ErrorAction Stop

                } catch {

                    Write-Error -Message ('Failed to get ACL for {0}: {1}' -f $Path, $_.Exception.Message)
                    return $false

                } #end try-catch

                # Add the access rule
                try {

                    $DirectorySecurity.SetAccessRule($FileSystemAccessRule)
                    Write-Verbose -Message ('Access rule created: {0} -> {1} ({2})' -f $Identity, $Permission, $AccessControlType)

                } catch {

                    Write-Error -Message ('Failed to add access rule: {0}' -f $_.Exception.Message)
                    return $false

                } #end try-catch

                # Apply the modified ACL
                try {

                    Set-Acl -Path $Path -AclObject $DirectorySecurity -ErrorAction Stop
                    Write-Verbose -Message ('Successfully granted {0} permissions to {1} on {2}' -f $Permission, $Identity, $Path)
                    $Result = $true

                } catch {

                    Write-Error -Message ('Failed to set ACL on {0}: {1}' -f $Path, $_.Exception.Message)
                    return $false

                } #end try-catch

            } #end if

        } catch {

            Write-Error -Message ('Error granting NTFS permissions: {0}' -f $_.Exception.Message)
            $Result = $false

        } #end try-catch

    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.FooterHousekeeping) {

            $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
                'granting NTFS permissions.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $Result
    } #end End

} #end Function Grant-NTFSPermission
