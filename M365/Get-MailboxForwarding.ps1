<#
.SYNOPSIS
    Checks mailbox-level forwarding configuration in Exchange Online.
.DESCRIPTION
    Retrieves ForwardingAddress, ForwardingSmtpAddress, and DeliverToMailboxAndForward status.
.EXAMPLE
    .\Get-MailboxForwarding.ps1 -Mailbox "user@domain.com"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Mailbox
)

Get-Mailbox -Identity $Mailbox | Select-Object DisplayName, UserPrincipalName, ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward | Format-List
