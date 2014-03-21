function alert($BL) {
	
$body = "
Please be advised that $($env:computername) has detected itself on a DNS Blacklist: $($BL)

Sincerely,
Your mate
"
	$Subject = "$($env:computername) detected on $($BL) DNS Blacklist"
	
	# Message Object Creation
	$message = new-object System.Net.Mail.MailMessage
	$message.From = $fromaddress
	$message.To.Add($toaddress)
	$message.Subject = $Subject
	$message.body = $body
	
	# Server Connection Object Creation
	$smtp = new-object Net.Mail.SmtpClient($smtpserver)
	$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
	$smtp.Send($message)
	
}