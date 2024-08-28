Function Send-Email {
    <#
        .SYNOPSIS
            Sends an email using System.Net.Mail.SmtpClient.

        .DESCRIPTION
            This function sends an email to one or more recipients using the specified SMTP settings. It is designed to allow detailed control over mail sending parameters including CC and BCC.

        .PARAMETER Recipient
            The email address of the recipient. This parameter supports pipeline input.

        .PARAMETER Subject
            The subject of the email.

        .PARAMETER Body
            The body of the email, formatted as HTML.

        .PARAMETER From
            The sender's email address. Defaults to 'your.email@example.com'.

        .PARAMETER SmtpServer
            The SMTP server address. Defaults to 'smtp.example.com'.

        .PARAMETER SmtpPort
            The SMTP port to use. Defaults to 587.

        .PARAMETER Username
            The username for SMTP authentication.

        .PARAMETER Password
            The password for SMTP authentication. This should be provided securely.

        .PARAMETER Cc
            The CC recipients of the email. Multiple recipients can be provided as an array.

        .PARAMETER Bcc
            The BCC recipients of the email. Multiple recipients can be provided as an array.

        .PARAMETER Attachments
            A list of file paths for attachments.

        .PARAMETER UseSsl
            Specifies whether SSL should be used for the connection. Defaults to true.

        .EXAMPLE
            Send-Email -Recipient "primary@example.com" -Cc "other@example.com" -Bcc "hidden@example.com" -Subject "Quarterly Report" -Body "<h2>Please review the attached report.</h2>" -Username "user@example.com" -Password "password" -SmtpServer "smtp.example.com" -UseSsl $true

        .NOTES
            This function replaces the Send-MailMessage cmdlet with the more flexible .NET classes for sending emails.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Error                            | Microsoft.PowerShell.Utility
                New-Object                             | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]

    param (
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The email address of the recipient. This parameter supports pipeline input.',
            Position = 0)]
        [ValidateNotNullOrEmpty]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string]
        $Recipient,

        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The subject of the email.',
            Position = 1)]
        [ValidateNotNullOrEmpty]
        [string]
        $Subject,

        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The body of the email.',
            Position = 2)]
        [ValidateNotNullOrEmpty]
        [string]
        $Body,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The senders email address',
            Position = 3)]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string]
        $From,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The SMTP server address.',
            Position = 4)]
        [string]
        $SmtpServer,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The SMTP port to use',
            Position = 5)]
        [PSDefaultValue(Help = 'Default SMTP port is: 587.')]
        [int]
        $SmtpPort = 587,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The username for SMTP authentication.',
            Position = 6)]
        [string]
        $Username,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The password for SMTP authentication. This should be provided securely as [System.Security.SecureString].',
            Position = 7)]
        [System.Security.SecureString]
        $Password,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The CC recipients of the email. Multiple recipients can be provided as an array.',
            Position = 8)]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string[]]
        $Cc,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The BCC recipients of the email. Multiple recipients can be provided as an array.',
            Position = 9)]
        [ValidatePattern("^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$")]
        [string[]]
        $Bcc,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'A list of file paths for attachments.',
            Position = 10)]
        [string[]]
        $Attachments,

        [Parameter( Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Specifies whether SSL should be used for the connection. Defaults to true.',
            Position = 11)]
        [bool]
        $UseSsl

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
        $mailMessage = [System.Net.Mail.MailMessage]::new()

        # Validate and prepare credentials
        #$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $smtpCreds = New-Object System.Net.NetworkCredential($Username, $securePassword)

        $smtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
        $smtpClient.EnableSsl = $UseSsl
        $smtpClient.Credentials = $smtpCreds
        Write-Verbose 'SMTP client configured with SSL={0}.' -f $UseSsl
    } #end Begin

    Process {
        foreach ($rcpt in $Recipient) {

            $mailMessage.From = $From
            $mailMessage.To.Add($rcpt)
            $mailMessage.Subject = $Subject
            $mailMessage.Body = $Body
            $mailMessage.IsBodyHtml = $true

            if ($Cc) {
                foreach ($ccAddr in $Cc) {
                    $mailMessage.CC.Add($ccAddr)
                } #end ForEach
            } #end If

            if ($Bcc) {
                foreach ($bccAddr in $Bcc) {
                    $mailMessage.Bcc.Add($bccAddr)
                } #end ForEach
            } #end If

            # Handling attachments
            if ($Attachments) {
                foreach ($attachmentInput in $Attachments) {
                    if (Test-Path $attachmentInput -PathType Leaf) {
                        $attachment = New-Object System.Net.Mail.Attachment($attachmentInput)
                        $mailMessage.Attachments.Add($attachment)
                        Write-Verbose 'Attached file: {0}' -f $attachmentInput
                    } else {
                        # Assume the input is plain text and create a MemoryStream attachment
                        $stream = New-Object System.IO.MemoryStream
                        $writer = New-Object System.IO.StreamWriter($stream)
                        $writer.Write($attachmentInput)
                        $writer.Flush()
                        $stream.Position = 0
                        $attachment = New-Object System.Net.Mail.Attachment($stream, 'Attachment.txt', 'text/plain')
                        $mailMessage.Attachments.Add($attachment)
                        Write-Verbose 'Attached text content as Attachment.txt'
                    } #end If-Else
                } #end ForEach
            } #end If

            if ($PSCmdlet.ShouldProcess("$From to $rcpt", 'Send email')) {
                try {
                    $smtpClient.Send($mailMessage)
                    Write-Verbose '"Email successfully sent to {0}; CC: {1}; BCC: {2}' -f $rcpt, $($Cc -join ', '), $($Bcc -join ', ')
                } catch {
                    Write-Error 'Failed to send email to {0}: {1}' -f $rcpt, $_
                } #end Try-Catch
            } #end If

            $mailMessage.Attachments.Dispose()
            $mailMessage.Dispose()
        } #end ForEach
    } #end Process

    End {
        $smtpClient.Dispose()

        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished sending eMail."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
