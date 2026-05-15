<#
.SYNOPSIS
Finds a user's last password change date in Entra ID.
#>

Get-MgUser -UserId "user@domain.com" -Property LastPasswordChangeDateTime
