Remove-NetFirewallRule -DisplayName 'Line Guard - LAN' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - Test' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Line Guard - Test' -Direction Inbound -Protocol TCP -LocalPort 5173 -Action Allow -Profile Any -RemoteAddress Any
Write-Host "Opened port 5173 to ALL IPs for testing" -ForegroundColor Yellow
