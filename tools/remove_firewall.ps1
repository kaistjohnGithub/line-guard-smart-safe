Remove-NetFirewallRule -DisplayName 'Line Guard - Block All' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - Allow 10.50.5.13' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - Allow 10.50.5.11' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard Smart Safe' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - IP Whitelist' -ErrorAction SilentlyContinue
Write-Host "All Line Guard firewall rules removed." -ForegroundColor Green
