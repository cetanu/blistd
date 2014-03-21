#####################################
#
# IP Address
#
#####################################
#
# Enter your IP manually, or get it automatically
# using gwmi or some other method
#
# $ip = '127.0.0.1'
# $ip = (gwmi Win32_NetworkAdapterConfiguration|?{$_.IPEnabled -eq "True"}|Select -f 1).IPAddress[0]
$ip = ipconfig | select-string "(?<=IPv4.*?: )(?!192|172|10).*?$" |%{$_.Matches}|%{$_.Value}


#####################################
#
# Email settings
#
#####################################
$smtpserver = "smtp.email.com"
$Username = "username"
$Password = "password"

$fromaddress = "from@email.com"
$toaddress = "to@email.com"
