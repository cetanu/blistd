function email_alert($BL)
{	
	# Message Object Creation
	$message = new-object System.Net.Mail.MailMessage
	$message.To.Add($toaddress)
	$message.From    = $email_from
	$message.Subject = $email_subject
	$message.body    = $email_body
	
	# Server Connection Object Creation
	$smtp = new-object Net.Mail.SmtpClient($email_server)
	$smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password)
	$smtp.Send($message)
}
function log($string, $mode)
{
	(date -format "HH:mm:sstt, dd MMM yyyy | ") + $string | Out-file ".\blistd.log" -a -en ASCII
	switch ($mode)
	{
		default   { Write-Output  $string }
		"warning" { Write-Warning ($string + " Please check your configuration.");  }
		"error"   { Write-Error   ($string + " Please check your configuration."); exit }
		"network" { Write-Error   ($string + " Please check your internet connection."); exit }
	}
}


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
$ipaddress = "127.0.0.1"  # We are checking this address

# Email Settings
$email_server = "smtp.email.com"
$email_username = "username"
$email_password = "password"
$email_from = "from@email.com"
$email_to = "to@email.com"
$email_subject = "$($env:computername) detected on $($BL) DNS Blacklist"
$email_body = "Please be advised that $($env:computername)" + "`n" + `
              "has detected itself on a DNS Blacklist: $($BL)" + "`n" + `
              "Sincerely," + "`n" + `
              "Your mate."


# ----- Everything past this point 'should' not be modified. -----

# Check IP address for validity
$regex = "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

switch -regex ($ipaddress)
{
	"127\.0\.0\.1"  { log "Your IP address is set to the local loopback address." "warning" }
	"^(192|172|10)" { log "A valid, public IP address is required for this script to work." "error" }
	default         { log "Invalid IP specified." "error" }
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
			log "BLACKLISTED-`t$($reverse_ip).$($BL)"
			Try
			{
				email_alert($BL)
			}
			Catch
			{
				log "Failed to send email." "error"
			}
		}
	}
	sleep (Random -min 60 -max 14000)  # delay to avoid looking like a bot
}
