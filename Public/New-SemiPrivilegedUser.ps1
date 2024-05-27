Function New-SemiPrivilegedUser {
    <#
        .SYNOPSIS
            Creates a new Semi-Privileged user based on the AD Delegation Model.

        .DESCRIPTION
            This function creates a new Semi-Privileged user based on the Active Directory (AD) Delegation Model.
            It checks if the provided standard user exists, and if so, it creates a new Semi-Privileged user with the specified account type.
            It also sends notification emails and encrypted emails containing the password, if specified.

        .PARAMETER SamAccountName
            Identity of the user getting the new Admin Account (Semi-Privileged user).

        .PARAMETER EmailTo
            Valid Email of the target user. This address will be used to send information to her/him.

        .PARAMETER AccountType
            Must specify the account type. Valid values are T0 or T1 or T2

        .PARAMETER AdminUsersDN
            Distinguished Name of the container where the Admin Accounts are located.

        .PARAMETER From
            Valid Email of the sending user. This address will be used to send the information and for authenticate to the SMTP server.

        .PARAMETER CredentialUser
            User for authenticate to the SMTP server.

        .PARAMETER CredentialPassword
            Password for authenticate to the SMTP server. (User is E-mail address of sender)

        .PARAMETER SMTPserver
            SMTP server

        .PARAMETER SMTPport
            SMTP port

        .PARAMETER BodyTemplate
            Path to the body template file.

        .PARAMETER BodyImage
            Path to the attached image of body template.

        .PARAMETER PwdBodyTemplate
            Path to the body template file.

        .EXAMPLE
            New-SemiPrivilegedUser -samaccountname "JohnDoe" -accounttype "Admin" -emailto "john@example.com" -from "admin@example.com" -credentialUser "smtpuser" -credentialPassword "smtppassword" -smtphost "smtp.example.com" -smtpport 25 -bodytemplate "C:\Templates\NotificationEmailBody.html" -pwdbodytemplate "C:\Templates\PasswordEmailBody.html" -bodyimage "C:\Images\logo.png"

            This example creates a new Semi-Privileged user with the account type "Admin" for the standard user "JohnDoe".
            It sends notification emails to "john@example.com" using "admin@example.com" as the sender, and SMTP authentication credentials.
            It also specifies custom body templates for notification and encrypted password emails, and attaches an image to notification emails.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADUser                             | ActiveDirectory
                New-ADUser                             | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Get-Content                            | Microsoft.PowerShell.Management
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Warning                          | Microsoft.PowerShell.Utility
                Get-Culture                            | Microsoft.PowerShell.Utility
                New-Object                             | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-AdObjectType                       | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-RandomPassword                     | EguibarIT.HousekeepingPS
                Send-Email                             | EguibarIT.HousekeepingPS
        .NOTES
            Version:         1.0
            DateModified:    12/Sep/2022
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com
    #>

    [CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = 'Medium', DefaultParameterSetName = 'No-Email')]
    [OutputType([String])]

    Param (
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Identity of the user getting the new Admin Account (Semi-Privileged user).',
            Position = 0)]
        [Parameter(ParameterSetName = 'No-Email')]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [ValidateNotNullOrEmpty]
        $SamAccountName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Valid Email of the target user. This address will be used to send information to her/him.',
            Position = 1)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string]
        $EmailTo,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Must specify the account type. Valid values are T0 or T1 or T2',
            Position = 2)]
        [Parameter(ParameterSetName = 'No-Email')]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [ValidateSet('T0', 'T1', 'T2')]
        [string]
        $AccountType,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Distinguished Name of the container where the Admin Accounts are located.',
            Position = 3)]
        [Parameter(ParameterSetName = 'No-Email')]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $AdminUsersDN,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Valid Email of the sending user. This address will be used to send the information and for authenticate to the SMTP server.',
            Position = 4)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string]
        $From,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'User for authenticate to the SMTP server.',
            Position = 5)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [string]
        $CredentialUser,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password for authenticate to the SMTP server. (User is E-mail address of sender)',
            Position = 6)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [System.Security.SecureString]
        $CredentialPassword,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'SMTP server.',
            Position = 7)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [string]
        $SMTPserver,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'SMTP port number.',
            Position = 8)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [Parameter(ParameterSetName = 'PasswordByEmail')]
        [int]
        $SMTPport,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to the body template file.',
            Position = 9)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [string]
        $BodyTemplate,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to the attached image of body template.',
            Position = 10)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [string]
        $BodyImage,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to the body template file.',
            Position = 11)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [string]
        $PwdBodyTemplate
    )

    Begin {
        Write-Verbose -Message '|=> ************************************************************************ <=|'
        Write-Verbose -Message (Get-Date).ToShortDateString()
        Write-Verbose -Message ('  Starting: {0}' -f $MyInvocation.Mycommand)
        Write-Verbose -Message ('Parameters used by the function... {0}' -f (Get-FunctionDisplay $PsBoundParameters -Verbose:$False))

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        [String] $newSamAccountName = $null
        [String] $newPassword = Get-RandomPassword -PasswordLength 20 -Complexity 4
        [bool]$sendEmail = $false
        [bool]$sendPassword = $false
        [bool]$stdUserExist = $false
        [bool]$PrivilegedUserExist = $false

        # parameters variable for splatting CMDlets
        $Splat = [hashtable]::New()

        # Check if email address is provided
        if ($null -ne $EmailTo) {
            $sendEmail = $true
        } else {
            Write-Verbose '[PROCESS] Semi-Privileged user created. No EmailTo was provided, so no notification will be created. Password must be set again manually.'
            $sendEmail = $false
            $sendPassword = $false
        }

    } #end Begin

    Process {

        # Search for Non-Privileged user.
        $StdUser = Get-AdObjectType -Identity $PsBoundParameters['SamAccountName']

        # If exist, retrieve all corresponding properties.
        # Id does not exist, write a warning and exit script.
        if ($null -eq $StdUser) {
            Write-Warning '[WARNING] Standard User does not exist. Before creating a Semi-Privileged user, a standard user (Non-Privileged user) must exist. Make sure a standard user exists before proceeding.'

            $stdUserExist = $false
            $sendEmail = $false
            $sendPassword = $false
        } else {
            Write-Verbose '[PROCESS] Standard user (Non-Privileged user) found! Proceeding to create the Semi-Privileged user.'
            $stdUserExist = $true
        } #end If-Else


        ################################################################################
        # Standard user (Non-Privileged user) exists. Create the Semi-Privileged user
        If ($stdUserExist) {
            # Get the correct SamAccountName
            $newSamAccountName = '{0}_{1}' -f $user.SamAccountName, $AccountType.ToUpper()

            # Check if Surename exists, else use SamAccountName
            if ($null -ne $StdUser.Surname) {
                $Surename = $StdUser.Surname.ToUpper()
            } else {
                $Surename = $StdUser.samAccountName
            } #end If-Else

            # Check if GivenName exists, else use $null
            if ($null -ne $StdUser.GivenName) {
                $GivenName = (Get-Culture).TextInfo.ToTitleCase($StdUser.GivenName.ToLower())
            } else {
                $GivenName = $null
            } #end If-Else

            # Define mandatory attributes for new user
            $splat = @{
                SamAccountName        = $newSamAccountName
                CN                    = $newSamAccountName
                UserPrincipalName     = '{0}_{1}@{2}' -f $SamAccountName, $AccountType, $Variables.DnsFqdn
                Name                  = '{0}, {1} ({2})' -f $StdUser.Surname.ToUpper(), (Get-Culture).TextInfo.ToTitleCase($StdUser.GivenName.ToLower()), $PsBoundParameters['AccountType']
                DisplayName           = '{0}, {1} ({2})' -f $StdUser.Surname.ToUpper(), (Get-Culture).TextInfo.ToTitleCase($StdUser.GivenName.ToLower()), $PsBoundParameters['AccountType']
                Surname               = $Surename
                GivenName             = $GivenName
                AccountPassword       = $newPassword
                Description           = '{0} Admin account' -f $AccountType
                Path                  = $AdminUsersDN
                Enabled               = $true
                TrustedForDelegation  = $false
                AccountNotDelegated   = $true
                ChangePasswordAtLogon = $false
                ScriptPath            = $null
                HomeDrive             = $null
                HomeDirectory         = $null
                Replace               = @{
                    'employeeType'                  = $AccountType
                    'msNpAllowDialin'               = $false
                    'msDS-SupportedEncryptionTypes' = '24'
                }
                EmployeeNumber        = $StdUser.SID.Value.ToString()
                EmployeeType          = $AccountType.ToUpper()
            }

            # Define additional attributes for new user if those exist
            If ($StdUser.Company) {
                $Splat.Add('Company', $StdUser.Company)
            } #end If
            If ($StdUser.Country) {
                $Splat.Add('Country', $StdUser.Country)
            } #end If
            If ($StdUser.Department) {
                $Splat.Add('Department', $StdUser.Department)
            } #end If
            If ($StdUser.Division) {
                $Splat.Add('Division', $StdUser.Division)
            } #end If
            If ($StdUser.EmailAddress) {
                $Splat.Add('EmailAddress', $StdUser.EmailAddress)
                If (-Not ($PsBoundParameters['EmailTo'])) {
                    Write-Verbose '[PROCESS] EmailTo was not given, but found on standard user. Using this email as a recipient.'
                    $sendEmail = $true
                    $PsBoundParameters['EmailTo'] = $StdUser.EmailAddress
                } #end If
            } #end If
            If ($StdUser.EmployeeId) {
                $Splat.Add('EmployeeId', $StdUser.EmployeeId)
            } #end If
            If ($StdUser.MobilePhone) {
                $Splat.Add('MobilePhone', $StdUser.MobilePhone)
            } #end If
            If ($StdUser.Office) {
                $Splat.Add('Office', $StdUser.Office)
            } #end If
            If ($StdUser.OfficePhone) {
                $Splat.Add('OfficePhone', $StdUser.OfficePhone)
            } #end If
            If ($StdUser.Organization) {
                $Splat.Add('Organization', $StdUser.Organization)
            } #end If
            If ($StdUser.OtherName) {
                $Splat.Add('OtherName', $StdUser.OtherName)
            } #end If
            If ($StdUser.POBox) {
                $Splat.Add('POBox', $StdUser.POBox)
            } #end If
            If ($StdUser.PostalCode) {
                $Splat.Add('PostalCode', $StdUser.PostalCode)
            } #end If
            If ($StdUser.State) {
                $Splat.Add('State', $StdUser.State)
            } #end If
            If ($StdUser.StreetAddress) {
                $Splat.Add('StreetAddress', $StdUser.StreetAddress)
            } #end If
            If ($StdUser.Title) {
                $Splat.Add('Title', $StdUser.Title)
            } #end If
        } #end If

        # Create the user
        Try {
            $SemiPrivilegedAccount = New-ADUser @splat

            Write-Verbose -Message ('New Admin Account {0} of type {1} was created correctly.' -f $PsBoundParameters['SamAccountName'], $PsBoundParameters['AccountType'])

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {

            # Identity already exist exception. The account already exist... Modifying it!
            $PrivilegedUserExist = $true

        } Catch {
            throw
        } #end Try-Catch


        ################################################################################
        # The account already exist... Modifying it!
        If ($PrivilegedUserExist) {

            Write-Verbose -Message ('[PROCESS] The Semi-Privileged user {0} already exists. Modifying the account.' -f $newSamAccountName)

            # get the Semi-Privileged user
            $SemiPrivilegedAccount = Get-ADUser -Identity $newSamAccountName

            # Using the Splat variable above, update existing Semi-Privileged user
            try {
                # Set values on existing Semi-Privileged user
                Set-ADUser @Splat

                $sendEmail = $true
                $sendPassword = $false

                Write-Verbose -Message ('[PROCESS] Existing Semi-Privileged user {0} was modified successfully.' -f $newSamAccountName)

            } catch {
                Write-Verbose -Message ('Something went wrong while modifying existing Semi-Privileged user {0}.' -f $newSamAccountName)
                $sendEmail = $false
                $sendPassword = $false
                throw
            }

        } #end If


        ################################################################################
        # Send Email notification
        if ($sendEmail) {
            #Check if Body Template was passed
            If ($PsBoundParameters['BodyTemplate']) {
                # Get content from file (usually HTML text)
                $body = Get-Content -Path $PsBoundParameters['BodyTemplate'] -Raw
            } else {
                $body = @"
                <!DOCTYPE html>
<html>
<head>
	<style>
/* Font Definitions */

/* Style Definitions */
html, body {
	font-size:14px;
	font-family:`"Roboto`",`"sans-serif`";
	color:#444;
	}
p, li {
	margin-right:0cm;
	margin-left:0cm;
	font-size:14px;
	font-family:`"Roboto`",`"sans-serif`";
	color:#444;}
h1, h2, h3, h4 {
	font-family: "Exo 2",sansserfi;
	color:#4678b4;
}
	</style>
</head>
<body>
	<div align=center>
		<table border=0 cellspacing=0 cellpadding=0 width=600 style='width:450.0pt'>
			<tr>
				<td>
					<img width=600 height=200 src="C:\Users\RODRIGUEZEGUIBARVice\OneDrive-EguibarIT\_Scripts\LabSetup\SourceDC\Modules\Picture1.jpg" />
				</td>
			</tr>
		</table>
	<br>
		<span>
		<table border=0 cellspacing=0 cellpadding=0 width=600 style='width:450.0pt'>
			<tr>
				<td style='padding:0cm 0cm 0cm 0cm'>
					<h2><b>Announcement:</b> Operational Change on Active Directory Semi-Privileged Access Account.</h2>
					<p>
						As part of our continued improvement plans in our Active Directory #@DomainName@#, a new <i>'Delegation Model'</i>
						is been implemented. This model will enforce a set of security guidelines that have been authorized by
						the <b>ISO Security Team</b>, approved by our <b>Change and Release Control Committee</b> and
						will be implemented and maintained by the <b>Infrastructure Management Teams</b>.
					</p>
					<p>
					The main objective of these changes is to implement a strict segregation of duties model. In
					Active Directory, this means that anyone who needs to manage Active Directory objects such as
					Create/Change/Delete users, groups, computers, etc., will require a separate account, with
					the corresponding delegated rights. These accounts are independent and not associated with your
					standard daily usage  domain account. Below there is brief description of privileged accounts
					in the new model.
					</p>
					<table border=1>
						<tr border=1 style='background:black;color:silver'>
							<th>
								Account
							</th>
							<th>
								Description
							</th>
						</tr>
						<tr>
							<td style='background:#ffcccc'>
								<br>
								SamAccountName_T0 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for specific restricted operational task.
								Mainly infrastructure related.
								Also known as "Administration area" and/or Tier0.<br>
							</td>
						</tr>
						<tr>
							<td style='background:#ccffcc'>
								<br>
								SamAccountName_T1 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for Servers and/or /Services administration.
								Also known as "Servers area" and/or Tier1.<br>
							</td>
						</tr>
						<tr>
							<td style='background:#adc6e5'>
								<br>
								SamAccountName_T2 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for standard User/Group/PC administration.
								Also known as "Sites area" and/or Tier0.<br>
							</td>
						</tr>
					</table>
					<br>
					<p>
					One of the main changes to Active Directory is to implement a strict separation of permissions
					and rights. This means that anyone who needs to manage Active Directory objects (Create/Change/Delete
					users, groups, computers, etc.) does needs a separate account having the corresponding rights.
					</p>
					<p>
					Based on your current identified role, a new administrative account has been automatically generated.
					This account has been generated based on your current UserID (also known as SamAccountName).
					</p>
					<br>
						<TABLE>
							<TR>
								<TD style='background:black;color:silver'>
									<br>
									Your new Semi-Privileged UserID is: &nbsp; &nbsp;
									<br><br>
								</TD>
								<TD style='background:silver'>
									<span style='font-size:11.0pt;font-family:"Verdana","sans-serif";color:darkblue'>
										&nbsp;#@UserID@#&nbsp;
									</span>
								</TD>
							</TR>
						</TABLE>
					<p>
					You will receive your password in a  separate communication.
					</p>
					<p>
					As these Administrative Accounts are considered <b>'Semi-Privileged Accounts'</b> the only authorized team to
					manage (create, reset, and remove) these accounts are the <b>Infrastructure Management Teams</b>. In the
					event of requiring any of the previously mentioned services, please open a service request ticket to the
					corresponding team.
					</p>
					<p>
					For additional details you can get more information in our site at
					<a href="http://www.DelegationModel.eu">
						EguibarIT Delegation Model.
					</a>
					</p>
					<p>
					We appreciate your cooperation and collaboration in helping securing our environment.
					</p>
					<p>Sincerely,</p>
					<p>
					Eguibar Information Technology S.L.
					</p>
				</td>
			</tr>
		</table>
	</span>
	</div>
	<br>
	<hr>
	<div align=center><font size='2' color='696969' face='arial'>This e-mail has been automatically generated by AD Delegation Model toolset</font></div>
</body>
</html>
"@
            } #end If-else

            # Find pattern within body text and replace it with new Semi-Privileged SamAccountName
            $body = $body -replace '#@UserID@#', $SemiPrivilegedAccount

            # Find pattern within body text and replace it with DNS Domain Name (FQDN)
            $body = $body -replace '#@DomainName@#', $Variables.DnsFqdn

            # Check if any image was passed
            If ($PsBoundParameters['BodyImage']) {
                # Load the image file into a System.Drawing.Bitmap object
                $bmp = [System.Drawing.Bitmap]::FromFile($PsBoundParameters['BodyImage'])

                try {
                    # Save the Bitmap to the stream in BMP format
                    $bmp.Save($stream, [System.Drawing.Imaging.ImageFormat]::Bmp)
                    # Reset the stream position to the beginning
                    $stream.Position = 0

                    # Prepare the attachment using a memory stream
                    $attachment = New-Object System.Net.Mail.Attachment($stream, [System.IO.Path]::GetFileName($PsBoundParameters['BodyImage']), 'image/bmp')
                } finally {
                    # Ensure that the bitmap is disposed of to free resources
                    $bmp.Dispose()
                } #end Try-Finally
            } #end If

            # Compile the eMail
            $Splat = @{
                Recipient   = $PsBoundParameters['EmailTo']
                Subject     = 'New Semi-Privileged account based on the AD Delegation Model'
                Body        = $body
                Attachments = $attachment
                Username    = $PsBoundParameters['CredentialUser']
                Password    = $PsBoundParameters['CredentialPassword']
                SmtpServer  = $PsBoundParameters['SMTPserver']
                SmtpPort    = $PsBoundParameters['SMTPport']
                UseSsl      = $true
            }
            Try {
                # Send the email
                Send-Email @Splat
                Write-Verbose -Message '[PROCESS] Notification email sent successfully.'
            } catch {
                Write-Warning -Message 'Notification email could not be sent.'
                $sendPassword = $false
                throw
            } #end Try-Catch


        } else {
            Write-Verbose -Message '[PROCESS] Semi-Privileged user created. No notification will be created. Password must be set again manually.'
            $sendEmail = $false
            $sendPassword = $false
        } #end If


        ################################################################################
        # Send encrypted Email containing password


    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished creating/modifying Semi-Privileged user."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
