#
#   ______   __       __   ______   ______  _____    
#  /\  == \ /\ \     /\ \ /\  ___\ /\__  _\/\  __-.  
#  \ \  __< \ \ \____\ \ \\ \___  \\/_/\ \/\ \ \/\ \ 
#   \ \_____\\ \_____\\ \_\\/\_____\  \ \_\ \ \____- 
#    \/_____/ \/_____/ \/_/ \/_____/   \/_/  \/____/ 
#                                                  
#          https://github.com/cetanu/blistd
#

import re


class Blistd (object):
    def __init__(self, addresses):
        blacklists = update_dnsbl()
        for ip in addresses:
            ip = self.reverse_ip(ip)
            for blacklist in blacklists:
                #TODO: DNS Lookup on IP and Blacklist
                #TODO: If/Else Condition to see if the DNS comes back successful or not
                print "{}.{}".format(ip, blacklist)

    @staticmethod
    def log(string, mode):
        from datetime import datetime as dt
        logfile = open('blistd.log', 'r+')
        if mode == "error":
            message = str(dt.now()) + " | " + string + " Please check your configuration."
            exit()
        elif mode == "network":
            message = str(dt.now()) + " | " + string + " Please check your internet connection."
            exit()
        else:
            message = str(dt.now()) + " | " + string
        print message
        logfile.write(message)
        logfile.close()

    @staticmethod
    def email_alert(blacklist, ip):
        # User settings
        email_server = "mail.domain.com"
        email_from = "alerts@domain.com"
        email_to = "support@domain.com"
        email_signature = "Sincerely, Monitoring Server"
        email_subject = "{} detected on {} DNS Blacklist".format(ip, blacklist)
        email_body = "Please be advised that {} has detected" \
                     "itself on DNS Blacklist: {}" \
                     "{}".format(ip, blacklist, email_signature)
        # Perform email
        msg = mimetext(email_body)
        msg['Subject'] = email_subject
        msg['From'] = email_from
        msg['To'] = email_to
        smtp = smtplib.smtp(email_server)
        smtp.sendmail(email_from, [email_to], msg.as_string())
        smtp.quit()

    @staticmethod
    def reverse_ip(ip):
        regex = r'\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
        match = re.search(regex, ip)
        return match.group(4) + "." + match.group(3) + "." + match.group(2) + "." + match.group(1)

    @staticmethod
    def update_dnsbl():
        import urllib2
        import os
        match = ''
        dnsbls = []
        url = urllib2.urlopen('https://gist.github.com/cetanu/9697771')
        for line in url.readlines():
            if "View Raw" in line:
                match = re.search(r'.*View Raw.*?=\"(.*?)\"', line)
        self.log("Updating DNSBLs...")
        url = urllib2.urlopen(match.groups()[0])
        for dnsbl in url.readlines():
            dnsbls += [dnsbl.strip("\n")]
        return dnsbls
