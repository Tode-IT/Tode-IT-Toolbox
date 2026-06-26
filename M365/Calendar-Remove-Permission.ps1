# Set variables
$CalendarOwner     = "user.calendarowner@company.com"
$UserToRemove      = "user.removeaccess@company.com"

Write-Host "Removing permissions for $UserToRemove on $CalendarOwner's calendar..." -ForegroundColor Cyan

# Attempt to remove the permission entry
try {
    Remove-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserToRemove -Confirm:$false -ErrorAction Stop
    Write-Host "Successfully removed permissions for $UserToRemove." -ForegroundColor Green
} catch {
    Write-Host "Error: Could not remove permissions. Ensure the user exists and has rights on this calendar." -ForegroundColor Red
}
