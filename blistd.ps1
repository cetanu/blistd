#
# IP ADDRESS TO CHECK
#

$ip = "127.0.0.1" # This should be a public address


#
# EMAIL SETTINGS
#

# Server details
$smtpserver = "smtp.email.com"
$Username = "username"
$Password = "password"

# Address details
$email_from = "from@email.com"
$toaddress = "to@email.com"

# Message details
$email_body = "
Please be advised that $($env:computername)
has detected itself on a DNS Blacklist: $($BL)
Sincerely,
Your mate
"
$email_subject = "$($env:computername) detected on $($BL) DNS Blacklist"


#
# OBTAINING REVERSE IP
#

# Check IP address to ensure it is public
if ($ip -eq $null -or $ip -match "^(192|172|10)") {
	Write-Error "A valid, public IP address is required for this script to work. Please check your configuration."
	exit
}

# Match the ip with regex
$ip -match "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" | Out-Null

# Reverse each capture group
$reverse_ip = "$($Matches[4]).$($Matches[3]).$($Matches[2]).$($Matches[1])"


#
# FUNCTIONS
#

# Emailing
function alert($BL) {	
	# Message Object Creation
	$message = new-object System.Net.Mail.MailMessage
	$message.From = $email_from
	$message.To.Add($toaddress)
	$message.Subject = $email_subject
	$message.body = $email_body
	
	# Server Connection Object Creation
	$smtp = new-object Net.Mail.SmtpClient($smtpserver)
	$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
	$smtp.Send($message)
}

# Logging
function log ($string) {
	(date -format "HH:mm:sstt, dd MMM yyyy | ") + $string | Out-file ".\blistd.log" -a -en ASCII
	Write-Output $string
}

#
# BLACKLISTS
#

# Automatically download a list of DNSBLs from Gist. Update the list if there is a missing blacklist.
(Invoke-WebRequest https://gist.github.com/cetanu/9697771).content | ? {$_ -match '(?<=View Raw" href=")[^"]*'}
$url = $Matches[0]
$DNSBL = (Invoke-WebRequest $url).content


#
# MAIN
#

# Ignore errors, because we will get lots of nslookup failures (unless we are blacklisted :P)
$ErrorActionPreference = "SilentlyContinue"

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
			alert($BL)
		}
	}
	# Wait between 1 minute to 4 hours before next check, so that we don't look too robotic
	Sleep (Random -min 60 -max 14000)
}
