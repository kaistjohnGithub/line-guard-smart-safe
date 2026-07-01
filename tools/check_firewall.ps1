Write-Host "=== Rules for port 5173 ===" -ForegroundColor Cyan
Get-NetFirewallPortFilter | Where-Object LocalPort -eq '5173' | ForEach-Object {
    Get-NetFirewallRule -AssociatedNetFirewallPortFilter $_
} | Select-Object DisplayName, Enabled, Direction, Action | Format-Table -AutoSize

Write-Host "`n=== Line Guard rules ===" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object DisplayName -like '*Line Guard*' | Select-Object DisplayName, Enabled, Direction, Action | Format-Table -AutoSize

Write-Host "`n=== Docker rules ===" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object DisplayName -like '*Docker*' | Where-Object Direction -eq 'Inbound' | Select-Object DisplayName, Enabled, Action | Format-Table -AutoSize
