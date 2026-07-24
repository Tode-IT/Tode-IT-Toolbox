<#
.SYNOPSIS
    Retrieves inbox rules for a specific user in Exchange Online.
.DESCRIPTION
    Displays rule names, status, and specific actions such as ForwardTo, CopyTo, and RedirectTo.
.EXAMPLE
    .\Get-InboxRules.ps1 -Mailbox "user@domain.com"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Mailbox
)

Get-InboxRule -Mailbox $Mailbox | Select-Object Name, Enabled, Priority, Description, ForwardTo, CopyTo, RedirectTo | Format-List
