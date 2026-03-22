Remove-NetFirewallRule -DisplayName 'Line Guard - WiFi' -ErrorAction SilentlyContinue
New-NetFirewallRule `
  -DisplayName 'Line Guard - WiFi' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -Action Allow `
  -Profile Any
Write-Host "Port 5173 open on all interfaces." -ForegroundColor Green
