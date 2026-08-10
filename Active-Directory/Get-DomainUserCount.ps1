# Count total enabled users in the Active Directory domain
Write-Host "Counting total users in the domain..." -ForegroundColor Cyan

$UserCount = (Get-ADUser -Filter *).Count

Write-Host "Total Domain Users: $UserCount" -ForegroundColor Green
