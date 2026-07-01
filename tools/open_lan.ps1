Remove-NetFirewallRule -DisplayName 'Line Guard - WiFi' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - LAN' -ErrorAction SilentlyContinue

New-NetFirewallRule `
  -DisplayName 'Line Guard - LAN' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -RemoteAddress '10.50.5.0/24' `
  -Action Allow `
  -Profile Any

Write-Host "Done! Port 5173 open for 10.50.5.x subnet" -ForegroundColor Green
