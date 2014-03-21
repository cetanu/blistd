. ".\settings.ps1"
. ".\func\blacklists.ps1"
. ".\func\email.ps1"


$IPv4_regex = "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
$ip -match $IPv4_regex | Out-Null
$reverse_ip = "$($Matches[4]).$($Matches[3]).$($Matches[2]).$($Matches[1])"

$ErrorActionPreference = "SilentlyContinue"

While (1)
{
	ForEach ($BL in $DNSBL)
	{
		Write-Host "Checking $($reverse_ip).$($BL)" -f Yellow
		$blcheck = Start-Job {cmd /c nslookup -type=txt "$($reverse_ip).$($BL)"}
		Wait-Job $blcheck | Out-Null
		
		If ((Receive-Job $blcheck) -NotMatch "$($reverse_ip).$($BL)")
		{
			Write-Host "`t$($BL) - Clear`n" -f Green
		}
		Else
		{
			Write-Host "`t$($BL) - Blocked`n" -f Red
			alert($BL)
		}
	}
	# Wait between 1 minute to 4 hours before next check, so that we don't look too robotic
	Sleep (Random -min 60 -max 14000)
}
