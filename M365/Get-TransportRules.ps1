<#
.SYNOPSIS
    Audits enabled Exchange Online Transport (Mail Flow) rules.
.DESCRIPTION
    Lists active transport rules to check for global forwarding, BCC, or redirect actions.
.EXAMPLE
    .\Get-TransportRules.ps1
#>

Get-TransportRule | Where-Object { $_.Enabled -eq $true } | Select-Object Name, Priority, Mode, Description | Format-List
