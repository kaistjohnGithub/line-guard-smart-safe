Remove-NetFirewallRule -DisplayName 'Line Guard Smart Safe' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - IP Whitelist' -ErrorAction SilentlyContinue

New-NetFirewallRule `
  -DisplayName 'Line Guard - IP Whitelist' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -RemoteAddress '10.50.5.13','10.50.5.11' `
  -Action Allow `
  -Profile Any

Write-Host "Done. Allowed: 10.50.5.13, 10.50.5.11 on port 5173"
