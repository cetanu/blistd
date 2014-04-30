#
#   ______   __       __   ______   ______  _____    
#  /\  == \ /\ \     /\ \ /\  ___\ /\__  _\/\  __-.  
#  \ \  __< \ \ \____\ \ \\ \___  \\/_/\ \/\ \ \/\ \ 
#   \ \_____\\ \_____\\ \_\\/\_____\  \ \_\ \ \____- 
#    \/_____/ \/_____/ \/_/ \/_____/   \/_/  \/____/ 
#                                                  
#          https://github.com/cetanu/blistd/blistd.py
#

from datetime import datetime as dt
from email.mime.text import MIMEText
import smtplib
import urllib2
import socket
import random
import time
import os
import re


class Blistd (object):
    def __init__(self, addresses=None):
        self.DNSBL = self.__update__()  # Update DNSBLs from public gist
        if addresses is not None:
            if isinstance(addresses, str):
                self.check(addresses)
                self.__sleep__()
            elif isinstance(addresses, list):
                for ip in addresses:
                    self.check(ip)
                self.__sleep__()

    @staticmethod
    def __log__(string):
        print string
        try:  # If the file doesn't exist, create it
            logfile = open('blistd.log', 'a')
        except IOError:
            logfile = open('blistd.log', 'w+')
        message = str(dt.now()) + " | " + string
        logfile.write(message + "\n")
        logfile.close()

    def __email_alert__(self, ip, bl):
        self.__log__("Sending email alert...")
        # Email settings
        email_server = "mail.domain.com"  #TODO: add smtp authentication, with secure credential storage
        email_from = "alerts@domain.com"  #      I will probably get a proper library for this purpose.
        email_to = "support@domain.com"
        email_signature = "Sincerely, Monitoring Server"
        email_subject = "{} detected on {} DNS Blacklist".format(ip, bl)
        email_body = "Please be advised that {} has detected" \
                     "itself on DNS Blacklist: {}" \
                     "{}".format(ip, bl, email_signature)
        # Construct message
        msg = MIMEText(email_body)
        msg['Subject'] = email_subject
        msg['From'] = email_from
        msg['To'] = email_to
        # Send message
        try:
            smtp = smtplib.SMTP(email_server)
            smtp.sendmail(email_from, [email_to], msg.as_string())
            smtp.quit()
        except socket.error:
            self.__log__("Failed to send email")
            #exit() # If you want the program to close when it can't email, uncomment.

    def __reverseip__(self, ip):
        self.__log__("Reversing {}...".format(ip))
        regex = r'\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' \
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
        match = re.search(regex, ip)
        return "{}.{}.{}.{}".format(match.group(4), match.group(3), match.group(2), match.group(1))

    def __update__(self):
        self.__log__("Updating DNSBLs...")
        match = ''
        dnsbls = []
        url = urllib2.urlopen('https://gist.github.com/cetanu/9697771')
        for line in url.readlines():
            if "View Raw" in line:
                match = re.search(r'.*View Raw.*?=\"(.*?)\"', line)
        url = urllib2.urlopen(match.groups()[0])
        for dnsbl in url.readlines():
            dnsbls += [dnsbl.strip("\n")]
        return dnsbls
        
    def check(self, ip):
        forward_ip = ip
        reverse_ip = self.__reverseip__(ip)
        for bl in self.DNSBL:
            try:  # If lookup is successful, we're blacklisted
                socket.gethostbyname("{}.{}".format(reverse_ip, bl))
                self.__log__("{} - BLACKLISTED: {}".format(forward_ip, bl))
                self.__email_alert__(forward_ip, bl)
            except socket.gaierror:
                self.__log__("{} - OK: {}".format(forward_ip, bl))

    @staticmethod
    def __sleep__():
        # After work is done, rest for a while to appear less robotic
        sleep = random.randint(300, 14400)
        self.__log__("Sleeping for {} minutes...".format(sleep/60))
        time.sleep(sleep)

blistd = Blistd()
blistd.check("74.125.137.27")
