<#
.SYNOPSIS
Retrieves the total mailbox size for a specific user in Exchange Online.
#>

Get-ExoMailboxStatistics -Identity "user@domain.com" | Select-Object DisplayName, TotalItemSize
