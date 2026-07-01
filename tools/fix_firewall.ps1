# ลบ rule เก่าทั้งหมดสำหรับ port 5173
Get-NetFirewallPortFilter | Where-Object LocalPort -eq '5173' | ForEach-Object {
    $rule = Get-NetFirewallRule -AssociatedNetFirewallPortFilter $_
    Write-Host "Removing: $($rule.DisplayName)"
    Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
}

# ลบ rule Line Guard เก่า
Remove-NetFirewallRule -DisplayName 'Line Guard Smart Safe' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Line Guard - IP Whitelist' -ErrorAction SilentlyContinue

# Block port 5173 ทุก IP ก่อน
New-NetFirewallRule `
  -DisplayName 'Line Guard - Block All' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -Action Block `
  -Profile Any

# Allow เฉพาะ 2 IP
New-NetFirewallRule `
  -DisplayName 'Line Guard - Allow 10.50.5.13' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -RemoteAddress '10.50.5.13' `
  -Action Allow `
  -Profile Any

New-NetFirewallRule `
  -DisplayName 'Line Guard - Allow 10.50.5.11' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5173 `
  -RemoteAddress '10.50.5.11' `
  -Action Allow `
  -Profile Any

Write-Host "Done!" -ForegroundColor Green
Write-Host "Allowed: 10.50.5.13, 10.50.5.11"
Write-Host "Blocked: all other IPs"
