# Get Calendar Permissions for a user
$UserEmail = "User@domain.com"

Write-Host "Fetching calendar permissions for $UserEmail..." -ForegroundColor Cyan
Get-MailboxFolderPermission -Identity "$UserEmail:\Calendar" | Select-Object User, AccessRights
