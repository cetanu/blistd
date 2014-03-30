#
#   ______   __       __   ______   ______  _____    
#  /\  == \ /\ \     /\ \ /\  ___\ /\__  _\/\  __-.  
#  \ \  __< \ \ \____\ \ \\ \___  \\/_/\ \/\ \ \/\ \ 
#   \ \_____\\ \_____\\ \_\\/\_____\  \ \_\ \ \____- 
#    \/_____/ \/_____/ \/_/ \/_____/   \/_/  \/____/ 
#                                                  
#          https://github.com/cetanu/blistd
#

# IP Address Settings
$ipaddress      = "59.167.128.100"  # We are checking this address

# Email Settings
$email_server   = "smtp.email.com"
$email_username = "username"
$email_password = "password"
$email_from     = "from@email.com"
$email_to       = "to@email.com"
$email_subject  = "$($env:computername) detected on $($blacklist) DNS Blacklist"
$email_body     = "Please be advised that $($env:computername)" + "`n" + `
                  "has detected itself on a DNS Blacklist: $($blacklist)" + "`n" + `
                  "Sincerely," + "`n" + `
                  "Your mate."


# ----- Everything past this point 'should' not be modified. -----



function email_alert($blacklist)
{	
	# Message Object Creation
	$message         = New-Object System.Net.Mail.MailMessage
	$message.From    = $email_from
	$message.Subject = $email_subject
	$message.body    = $email_body
	$message.To.Add($email_to)
	
	# Server Connection Object Creation
	$smtp = New-Object Net.Mail.SmtpClient($email_server)
	$smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password)
	$smtp.Send($message)
}
function log($string, $mode)
{
	(date -format "HH:mm:sstt, dd MMM yyyy | ") + $string | Out-file ".\blistd.log" -a -en ASCII
	switch ($mode)
	{
		default   { Write-Output   $string }
		"warning" { Write-Warning ($string + " Please check your configuration.");  }
		"error"   { Write-Error   ($string + " Please check your configuration."); exit }
		"network" { Write-Error   ($string + " Please check your internet connection."); exit }
	}
}

# Check IP address for validity
$regex = "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

switch -regex ($ipaddress)
{
	"^(192|172|10)" { log "A valid, public IP address is required for this script to work." "error" }
	"127\.0\.0\.1"  { log "Your IP address is set to the local loopback address." "warning" }
	default         { log "Invalid IP specified." "error" }
	$regex          { continue }
}
$ipaddress -match $regex | Out-Null
$reverse_ip = "$($Matches[4]).$($Matches[3]).$($Matches[2]).$($Matches[1])"  # Reverse each capture group

# Blacklists
log "Updating DNSBLs..."
Try
{
	(Invoke-WebRequest 'https://gist.github.com/cetanu/9697771').content | ?{$_ -match '(?<=View Raw" href=")[^"]*'} | Out-Null
	$URL = $Matches[0]
	$DNSBL = ((Invoke-WebRequest $URL).content -split "\n")  # Automatically download a list of DNSBLs from Gist
	log "Done.`n"
}
Catch
{
	log "Failed to retrieve DNSBLs." "network"
}

# Begin checking
$ErrorActionPreference = "SilentlyContinue"  # Ignore errors, we are supposed to get nslookup failures
While (1)
{
	ForEach ($blacklist in $DNSBL)
	{
		$check = Start-Job {cmd /c nslookup -type=txt "$($reverse_ip).$($blacklist)"}
		Wait-Job $check | Out-Null
		
		If ((Receive-Job $check) -NotMatch "$($reverse_ip).$($blacklist)")
		{
			log "OK -`t$($reverse_ip).$($blacklist)"
		}
		Else
		{
			log "BLACKLISTED-`t$($reverse_ip).$($blacklist)"
			Try
			{
				email_alert($blacklist)
			}
			Catch
			{
				log "Failed to send email." "error"
			}
		}
	}
	$delay = (Random -min 60 -max 14000)
	log "Sleeping for $([int]($delay/60)) minutes"
	sleep $delay  # random delay to avoid looking like a bot
}
