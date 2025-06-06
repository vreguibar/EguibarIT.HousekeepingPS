function Grant-NTFSPermission {
    <#
        .Synopsis
            Function to Add NTFS permissions to a folder
        .DESCRIPTION
            Function to Add NTFS permissions to a folder
        .EXAMPLE
            Grant-NTFSPermission -Path 'C:\Shares' -Object 'TheGood' -Permissions 'FullControl'
        .PARAMETER path
            Absolute path to the object
        .PARAMETER object
            Name of the Identity getting the permission.
        .PARAMETER permission
            Permission of the object
        .NOTES
            Version:         1.1
            DateModified:    03/Oct/2016
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]

    Param (
        # Param1 path to the resource|folder
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Absolute path to the object',
            Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $path,

        # Param2 object or SecurityPrincipal
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Name of the Identity getting the permission.',
            Position = 1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $object,

        # Param3 permission
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'Permission of the object',
            Position = 2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $permission
    )

    Begin {
        $error.Clear()

        $txt = ($Variables.Header -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Module imports

        ##############################
        # Variables Definition

        # Possible values for FileSystemRights are:
        # ReadAndExecute, AppendData, CreateFiles, read, write, Modify, FullControl
        $FileSystemRights = [Security.AccessControl.FileSystemRights]$PSBoundParameters['permission']

        $InheritanceFlag = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        $PropagationFlag = [Security.AccessControl.PropagationFlags]::None
        $AccessControlType = [Security.AccessControl.AccessControlType]::Allow
    } #end Begin

    Process {
        Try {
            $Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $PSBoundParameters['object']

            $FileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList ($Account, $FileSystemRights, $InheritanceFlag, $PropagationFlag, $AccessControlType)

            $DirectorySecurity = Get-Acl -Path $PSBoundParameters['path']

            $DirectorySecurity.AddAccessRule($FileSystemAccessRule)

            Set-Acl -Path $PSBoundParameters['path'] -AclObject $DirectorySecurity
        } catch {
            Write-Error -Message 'Error granting NTFS permissions'
            throw
        } #end Try-Catch
    } #end Process

    End {
        $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
            'changing NTFS permissions.'
        )
        Write-Verbose -Message $txt
    } #end End

} #end Function
