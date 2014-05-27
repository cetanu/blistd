#
#          https://github.com/cetanu/blistd/blistd.ps1
#

# IP Address Settings
$ipaddress       = @("4.2.2.1", "127.0.0.1")
$reverse_ip      = @()  # Leave this blank

# Email Settings
$email_server    = "emailserver.domain.com"
$email_from      = "sender@domain.com"
$email_to        = "recipient@domain.com"
$email_signature = "Sincerely,`nYourName."



# ----- Everything past this point 'should' not be modified. -----

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

# Email Credentials. Must be run by the same user everytime, or you won't be able to decrypt the pwd.
$email_user =  # This will be automatically filled when you run the script.
$email_pass =  # This will be automatically filled when you run the script.

if ($email_pass -eq $null -or $email_user -eq $null)
{
	$credentials = credential -message "Please enter your email username and password"
    
	if ($credentials -eq $null)
    {
        log "No credentials provided." "error"
    }
    
	(gc ".\blistd.ps1") `
		-replace "^.email_user =.*?$",('$email_user = ' + "'" + $credentials.UserName + "'") `
		-replace "^.email_pass =.*?$",('$email_pass = ' + "'" + ($credentials.Password | ConvertFrom-SecureString) + "'" + " | ConvertTo-SecureString") |
		sc ".\blistd.ps1"
}

function email_alert($blacklist, $ip)
{	
    # Add Hostname/IP to email body/subject
    $ip = $ip.split("\."); [array]::Reverse($ip); $ip = $ip -join "."
    $hostname = [System.Net.DNS]::GetHostByAddress($ip).Hostname
    $email_subject   = "$($hostname) [$($ip)] detected on $($blacklist) DNS Blacklist"
    $email_body      = "Please be advised that $($hostname) $($ip)" + "`n" + `
                       "has detected itself on a DNS Blacklist: $($blacklist)" + "`n" + `
                       "$($email_signature)"

	# Message Object Creation
	$message         = New-Object System.Net.Mail.MailMessage
	$message.From    = $email_from
	$message.Subject = $email_subject
	$message.body    = $email_body
	$message.To.Add($email_to)
	
	# Server Connection Object Creation
	$smtp.Credentials = New-Object System.Net.NetworkCredential($email_user,$email_pass)
	Try
	{
    		$smtp = New-Object Net.Mail.SmtpClient($email_server, 587)
		$smtp.EnableSSL = $true
		$smtp.Send($message)
		log "Email sent to: $($email_to)"
	}
	Catch
	{
        	log "SMTPS failed. Trying regular SMTP" "warning"
        	Try
        	{
            		$smtp = New-Object Net.Mail.SmtpClient($email_server)
            		$smtp.Send($message)
            		log "Email sent to: $($email_to)"
        	}
        	Catch
        	{
            		log "SMTP failed. $($error[0].Exception)" "error"
        	}
	}
}

# Check IP address for validity
$regex = "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\." + `
           "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

# Create an array of each reverse address
ForEach ($ip in $ipaddress)
{
    switch -regex ($ip)
    {
        "^(192|172|10)" { log "A valid, public IP address is required for this script to work." "error" }
        "127\.0\.0\.1"  { log "Your IP address is set to the local loopback address." "warning" }
        default         { log "Invalid IP specified." "error" }
        $regex          { continue }
    }
    $ipaddress -match $regex | Out-Null
    $reverse_ip += @("$($Matches[4]).$($Matches[3]).$($Matches[2]).$($Matches[1])")  # Reverse each capture group
}

# Blacklists
log "Updating DNSBLs..."
Try
{
	# Tell the user when the gist was last updated
	(Invoke-WebRequest 'https://gist.github.com/cetanu/9697771/revisions').content |
	? {$_ -match 'cetanu<\/a> \w+<.*?> this gist.*?>([^<]*)'} | Out-Null
	
	# Tell them the latest revision date and give them the choice to continue or exit
	$Choice = Read-Host "The DNSBL list was last updated $(date $Matches[1]), continue? [y/n]"
	If (! $Choice.ToLower().StartsWith("y"))
	{
		# Log the gist link so users can check the contents
		log "Declined DNSBL download. Please check the public gist: https://gist.github.com/cetanu/9697771"
		exit
	}
	
	# Update the DNSBL from my public gist
	(Invoke-WebRequest 'https://gist.github.com/cetanu/9697771').content |
	? {$_ -match '(?<==")(.*?raw[^"]*?)'} | Out-Null
	
	# Automatically download a list of DNSBLs from Gist
	$DNSBL = ((Invoke-WebRequest $Matches[0]).content -split "\n")  
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
    ForEach ($ip in $reverse_ip)  # Loop through each IP
    {
	    ForEach ($blacklist in $DNSBL)  # Loop through each BL
	    {
	    	$check = Start-Job {cmd /c nslookup -type=txt "$($ip).$($blacklist)"}
	    	Wait-Job $check | Out-Null
	    	
	    	If ((Receive-Job $check) -NotMatch "$($ip).$($blacklist)")
	    	{
	    		log "OK -`t$($ip).$($blacklist)"
	    	}
	    	Else
	    	{
	    		log "BLACKLISTED-`t$($ip).$($blacklist)"
	    		email_alert $blacklist $ip
	    	}
	    }
    }
	$delay = (Random -min 60 -max 14000)
	log "Sleeping for $([int]($delay/60)) minutes"
	sleep $delay  # random delay to avoid looking like a bot
}
