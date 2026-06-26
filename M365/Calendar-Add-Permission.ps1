# Set variables
$CalendarOwner     = "user.calendarowner@company.com"
$UserGettingAccess = "user.grantaccess@company.com"
$PermissionLevel   = "Editor" 

Write-Host "Granting $PermissionLevel access to $UserGettingAccess on $CalendarOwner's calendar..." -ForegroundColor Cyan

# Attempt to add permission. If it fails (because the user already has rights), update it instead.
try {
    Add-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserGettingAccess -AccessRights $PermissionLevel -ErrorAction Stop
    Write-Host "Successfully added permissions." -ForegroundColor Green
} catch {
    Write-Host "Permission already exists. Updating instead..." -ForegroundColor Yellow
    Set-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserGettingAccess -AccessRights $PermissionLevel
    Write-Host "Successfully updated existing permissions." -ForegroundColor Green
}
