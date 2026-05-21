# Set or Modify Calendar Permissions for a user
$CalendarOwner     = "user.calendarowner@company.com"
$UserGettingAccess = "user.grantaccess@company.com"
$PermissionLevel   = "Editor" # Options: Reviewer, Author, Editor, Owner

Write-Host "Updating permissions to $PermissionLevel for $UserGettingAccess on $CalendarOwner's calendar..." -ForegroundColor Cyan

# Checks if a permission already exists to prevent errors, then applies the change
try {
    Set-MailboxFolderPermission -Identity "$CalendarOwner:\Calendar" -User $UserGettingAccess -AccessRights $PermissionLevel -ErrorAction Stop
    Write-Host "Successfully updated existing permissions!" -ForegroundColor Green
} catch {
    Write-Host "No existing permission found. Creating a new permission entry..." -ForegroundColor Yellow
    Add-MailboxFolderPermission -Identity "$CalendarOwner:\Calendar" -User $UserGettingAccess -AccessRights $PermissionLevel
    Write-Host "Successfully added new permissions!" -ForegroundColor Green
}
