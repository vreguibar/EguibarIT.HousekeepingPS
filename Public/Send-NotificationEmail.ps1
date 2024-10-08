function Send-NotificationEmail {
    param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Email address of the recipient (to whom) of the email.',
            Position = 0)]
        [ValidateScript({ Test-EmailAddress -EmailAddress $_ })]
        [ValidateNotNullOrEmpty()]
        [Alias('Recipient', 'EmailTo')]
        [string]
        $To,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Subject of the email.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Subject,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Body (content) of the email.',
            Position = 2)]
        [string]
        $Body,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'FQDN or IP Address of the SMTP to be used for sending this email.',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SmtpServer,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'SMTP port to be used for sending this email.',
            Position = 4)]
        [ValidateNotNullOrEmpty()]
        [int]
        $SmtpPort,

        [Parameter( Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'The username for SMTP authentication.',
            Position = 5)]
        [string]
        $Username,

        [Parameter( Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'The password for SMTP authentication. This should be provided securely as [System.Security.SecureString].',
            Position = 6)]
        [System.Security.SecureString]
        $Password,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Path to any required attachment.',
            Position = 7)]
        [string]
        $AttachmentPath
    )

    Begin {

        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Variables Definition

        $emailParams = @{
            Recipient  = $PSBoundParameters['To']
            From       = 'DelegationModel@EguibarIT.com'
            Subject    = $PSBoundParameters['Subject']
            SmtpServer = $PSBoundParameters['SmtpServer']
            SmtpPort   = $PSBoundParameters['SmtpPort']
            UseSsl     = $true
            Username   = $PSBoundParameters['Username']
            Password   = $PSBoundParameters['Password']
        }

        if ($AttachmentPath -and (Test-Path $AttachmentPath)) {
            $emailParams['Attachments'] = $AttachmentPath
        }

        if (-not $PSBoundParameters.ContainsKey('Body')) {

            # No body parsed. Using following body:
            $Body = @'
			<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="UTF-8">
				<meta name="viewport" content="width=device-width, initial-scale=1.0">
				<title>Operational Change Notification</title>
				<style>
					/* Reset some default styles */
					body, h1, h2, h3, p, ul, table {
						margin: 0;
						padding: 0;
						border: 0;
						font-size: 100%;
						vertical-align: baseline;
					}

					/* Global Styles */
					body {
						font-family: "Roboto", "Arial", sans-serif;
						line-height: 1.6;
						color: #444;
						background-color: #f4f4f4;
						margin: 20px;
					}

					h1, h2, h3, h4 {
						font-family: "Exo 2", sans-serif;
						color: #4678b4;
						margin-bottom: 15px;
					}

					h2 {
						font-size: 1.8em;
						margin-bottom: 20px;
					}

					p, li {
						font-size: 1em;
						margin-bottom: 15px;
						line-height: 1.8;
					}

					a {
						color: #4678b4;
						text-decoration: none;
					}

					a:hover {
						text-decoration: underline;
					}

					.container {
						max-width: 800px;
						margin: 0 auto;
						padding: 20px;
						background-color: #ffffff;
						border-radius: 8px;
						box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
					}

					.header img {
						width: 100%;
						border-radius: 8px 8px 0 0;
					}

					.content {
						padding: 20px;
					}

					.content p {
						margin-bottom: 20px;
					}

					.account-table {
						width: 100%;
						border-collapse: collapse;
						margin-top: 20px;
					}

					.account-table th, .account-table td {
						padding: 12px;
						text-align: left;
						border: 1px solid #ccc; /* Adding borders to cells */
					}

					.account-table th {
						background-color: #030f1e;
						color: #e5ecfa;
						font-weight: bold;
					}

					/* Specific Row Colors */
					.tier-0 {
						background-color: #ffcccc !important; /* Light Red */
					}

					.tier-1 {
						background-color: #ccffcc !important; /* Light Green */
					}

					.tier-2 {
						background-color: #adc6e5 !important; /* Light Blue */
					}

					.highlight-row td {
						background-color: #fff3cd;
						color: #856404;
						font-weight: bold;
					}

					.footer {
						text-align: center;
						margin-top: 30px;
						font-size: 0.875em;
						color: #777;
					}

					@media screen and (max-width: 600px) {
						.container {
							padding: 15px;
						}

						h2 {
							font-size: 1.5em;
						}

						.account-table th, .account-table td {
							padding: 10px;
						}
					}
				</style>
			</head>
			<body>
				<div class="container">
					<div class="header">
						<img src="./Header.jpg" alt="Header Image">
					</div>
					<div class="content">
						<h2>Operational Change on Active Directory Semi-Privileged Access Account</h2>
						<p>As part of our continued improvement plans in our Active Directory <strong>#@DomainName@#</strong>, a new <a href="http://www.DelegationModel.eu">'Delegation Model'</a> is being implemented. This model will enforce a set of security guidelines authorized by the <strong>IT Security Team</strong>, approved by our <strong>Change and Release Control Committee</strong>, and implemented by the <strong>Active Directory Team</strong>.</p>

						<p>The main objective of these changes is to implement a strict <a href="https://eguibarit.eu/segregation-of-duties/">Segregation of Duties</a> model. In Active Directory, this means that anyone who needs to manage Active Directory objects (e.g., Create/Change/Delete users, groups, computers) will require a separate account with the corresponding delegated rights. These accounts are independent and not associated with your standard daily usage domain account. Below is a brief description of the privileged accounts in the new model:</p>

						<table class="account-table">
							<tr>
								<th>Account</th>
								<th>Description</th>
							</tr>
							<tr class="tier-0">
								<td>SamAccountName_T0</td>
								<td>Reserved for specific restricted operational tasks, mainly infrastructure-related. Also known as "Administration area" and/or <a href="https://www.delegationmodel.com/ad-delegation-model-admin-area-tier0/">Tier 0</a>.</td>
							</tr>
							<tr class="tier-1">
								<td>SamAccountName_T1</td>
								<td>Reserved for Servers and/or Services administration. Also known as "Servers area" and/or <a href="https://www.delegationmodel.com/ad-delegation-model-servers-area-tier1/">Tier 1</a>.</td>
							</tr>
							<tr class="tier-2">
								<td>SamAccountName_T2</td>
								<td>Reserved for standard User/Group/PC administration. Also known as "Sites area" and/or <a href="https://www.delegationmodel.com/ad-delegation-model-sites-area-tier2/">Tier 2</a>.</td>
							</tr>
						</table>

						<p>One of the main changes to Active Directory is the implementation of a strict separation of permissions and rights, enforcing "<a href="https://eguibarit.eu/least-privileged-access/">Least Privilege Access</a>". This means that anyone who needs to manage Active Directory objects will need a separate account with the corresponding rights.</p>

						<p>Based on your current identified role, a new administrative account has been automatically generated. This account is based on your current UserID (also known as SamAccountName).</p>

						<table class="account-table highlight-row">
							<tr>
								<td>Your new Semi-Privileged UserID is:</td>
								<td><span style="color: darkblue; font-size: 1.2em;">#@UserID@#</span></td>
							</tr>
						</table>

						<p>You will receive your password in a separate communication.</p>

						<p>As these Administrative Accounts are considered <a href="https://eguibarit.eu/privileged-semi-privileged-users/"><strong>'Semi-Privileged Accounts'</strong></a>, the only authorized team to manage (create, reset, and remove) these accounts is the <strong>Active Directory Team</strong>. If you require any of the mentioned services, please open a service request ticket with the corresponding team.</p>

						<p>For additional details, you can find more information on our site at <a href="http://www.DelegationModel.eu">EguibarIT Delegation Model</a>.</p>

						<p>We appreciate your cooperation and collaboration in helping to secure our environment.</p>

						<p>Sincerely,</p>
						<p>EguibarIT</p>
					</div>
					<div class="footer">
						<hr>
						<p>This e-mail has been automatically generated by the AD Delegation Model toolset.</p>
					</div>
				</div>
			</body>
			</html>
'@
            $emailParams.Add('Body', $Body)
        } else {
            $emailParams.Add('Body', $PSBoundParameters['Body'])
        }
    } #end Begin

    Process {
        try {

            Send-Email @emailParams

            Write-Verbose -Message ('Sent email to {0}' -f $To)
        } catch {
            Write-Error -Message ('Error sending email to {0}: {1}' -f $To, $_)
            throw
        }
    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'sending notification email on Semi-Privileged user creation.'
        )
        Write-Verbose -Message $txt
    } #end End
}
