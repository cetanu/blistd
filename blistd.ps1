# IP Address Settings
$ipaddress = "127.0.0.1"  # We are checking this address
if ($ipaddress -eq $null -or $ipaddress -match "^(192|172|10)")
{
	Write-Error "A valid, public IP address is required for this script to work. Please check your configuration."
	exit
}
$ipaddress -match "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" | Out-Null
$reverse_ip = "$($Matches[4]).$($Matches[3]).$($Matches[2]).$($Matches[1])"  # Reverse each capture group

# Email Settings
$email_server = "smtp.email.com"
$email_username = "username"
$email_password = "password"
$email_from = "from@email.com"
$email_to = "to@email.com"
$email_subject = "$($env:computername) detected on $($BL) DNS Blacklist"
$email_body = "
Please be advised that $($env:computername)
has detected itself on a DNS Blacklist: $($BL)
Sincerely,
Your mate
"

# Functions
function email_alert($BL)
{	
	# Message Object Creation
	$message = new-object System.Net.Mail.MailMessage
	$message.From = $email_from
	$message.To.Add($toaddress)
	$message.Subject = $email_subject
	$message.body = $email_body
	
	# Server Connection Object Creation
	$smtp = new-object Net.Mail.SmtpClient($email_server)
	$smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password)
	$smtp.Send($message)
}
function log($string)
{
	(date -format "HH:mm:sstt, dd MMM yyyy | ") + $string | Out-file ".\blistd.log" -a -en ASCII
	Write-Output $string
}

# Blacklists
Write-Output "Updating DNSBLs..."
(Invoke-WebRequest 'https://gist.github.com/cetanu/9697771').content | ? {$_ -match '(?<=View Raw" href=")[^"]*'} | Out-Null
$URL = $Matches[0]
$DNSBL = ((Invoke-WebRequest $URL).content -split "\n")  # Automatically download a list of DNSBLs from Gist
Write-Output "Done.`n"

# Begin checking
$ErrorActionPreference = "SilentlyContinue"  # Ignore errors, we are supposed to get nslookup failures
While (1)
{
	ForEach ($BL in $DNSBL)
	{
		$blcheck = Start-Job {cmd /c nslookup -type=txt "$($reverse_ip).$($BL)"}
		Wait-Job $blcheck | Out-Null
		
		If ((Receive-Job $blcheck) -NotMatch "$($reverse_ip).$($BL)")
		{
			log "OK -`t$($reverse_ip).$($BL)"
		}
		Else
		{
			log "LISTED-`t$($reverse_ip).$($BL)"
			email_alert($BL)
		}
	}
	Sleep (Random -min 60 -max 14000)  # delay to avoid looking like a bot
}
