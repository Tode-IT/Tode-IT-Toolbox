# Export members of an Active Directory Group to CSV
$GroupName = Read-Host "Enter the AD Group Name"
$OutputPath = "C:\Source\GroupMembers_$GroupName.csv"

Write-Host "Fetching members for $GroupName..." -ForegroundColor Cyan

Get-ADGroupMember -Identity $GroupName -Recursive | 
    Select-Object Name, ObjectClass, DisplayName | 
    Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Export completed successfully! Saved to $OutputPath" -ForegroundColor Green
